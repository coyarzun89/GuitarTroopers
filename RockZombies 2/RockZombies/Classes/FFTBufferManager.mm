#include "FFTBufferManager.h"
#include <vector>
#include <cmath>
#include <algorithm>

#define min(x,y) (x < y) ? x : y

FFTBufferManager::FFTBufferManager(UInt32 inNumberFrames, UInt32 hwSampleRate) :
mNeedsAudioData(0),
mHasAudioData(0),
mNumberFrames(inNumberFrames),
mSampleRate(hwSampleRate),
mAudioBufferSize(inNumberFrames * sizeof(int32_t)),
mAudioBufferCurrentIndex(0)

{
    prevFreq = -1;
    prevIntensidad = 0;
    isAmbiental = true;
    silence = true;

	mAudioBuffer = (int32_t*)malloc(mAudioBufferSize * sizeof(int32_t));
	mSpectrumAnalysis = SpectrumAnalysisCreate(mNumberFrames);
	OSAtomicIncrement32Barrier(&mNeedsAudioData);
    
    guitarFrequencySpectrum = (double*)malloc(120*sizeof(double));
    guitarFrequencySpectrum[29] = 440;
    for (int i = 1; i < 30; i++)
    {
        guitarFrequencySpectrum[30 - i - 1] = 440 / pow(2, ((double)i / 12));
        guitarFrequencySpectrum[i + 30 - 1] = 440 * pow(2, ((double)i / 12));
    }
    for (int i = 1; i <= 60; i++)
        guitarFrequencySpectrum[i + 59 - 1] = guitarFrequencySpectrum[59 - 1] * pow(2, ((double)i / 12));
    
    CT = (double**)malloc(6*sizeof(double*));
    for(int i = 0; i < 6; i++){
        CT[i] = (double*)malloc(25*sizeof(double));
        for(int j = 0; j < 25; j++){
            switch (i){
                case 5: //eHigh
                    CT[5][j] = guitarFrequencySpectrum[j + 25 - 1];
                    break;
                case 4: //B
                    CT[4][j] = guitarFrequencySpectrum[j + 20 - 1];
                    break;
                case 3: //G
                    CT[3][j] = guitarFrequencySpectrum[j + 16 - 1];
                    break;
                case 2: //D
                    CT[2][j] = guitarFrequencySpectrum[j + 11 - 1];
                    break;
                case 1: //A
                    CT[1][j] = guitarFrequencySpectrum[j + 6 - 1];
                    break;
                case 0: //eLow
                    CT[0][j] = guitarFrequencySpectrum[j + 1 - 1];
                    break;
                default:
                    break;
            }
        }
    }
    
    // Variables Auxiliares
    lengthFFT = mNumberFrames / 2;
    maxFreq = 4804.6875;
    duration = ((double)mNumberFrames / (double)mSampleRate);
    bw = ((double)mSampleRate / (double)mNumberFrames);
    lengthUsefulFFT = (int)(maxFreq*duration);
}

FFTBufferManager::~FFTBufferManager(){
	free(mAudioBuffer);
	SpectrumAnalysisDestroy(mSpectrumAnalysis);
}

void FFTBufferManager::GrabAudioData(AudioBufferList *inBL){
	if (mAudioBufferSize < inBL->mBuffers[0].mDataByteSize)	return;
	
	UInt32 bytesToCopy = min(inBL->mBuffers[0].mDataByteSize, mAudioBufferSize - mAudioBufferCurrentIndex);
	memcpy(mAudioBuffer+mAudioBufferCurrentIndex, inBL->mBuffers[0].mData, bytesToCopy);
	
	mAudioBufferCurrentIndex += bytesToCopy / sizeof(int32_t);
	if (mAudioBufferCurrentIndex >= mAudioBufferSize / sizeof(int32_t)){
		OSAtomicIncrement32Barrier(&mHasAudioData);
		OSAtomicDecrement32Barrier(&mNeedsAudioData);
	}
}

Boolean	FFTBufferManager::ComputeFFT(int32_t *outFFTData){
	if (HasNewAudioData()){
        
        // Borramos la frecuencia anterior
        currentFrequency = -1;
        
        // Realizamos una FFT
		SpectrumAnalysisProcess(mSpectrumAnalysis, mAudioBuffer, outFFTData, false);
        
        // Cálculo de la intensidad promedio de la señal
        double intensity = 0;
        for(int i = 0; i < lengthFFT - 1; i++)
            intensity += outFFTData[i];
        intensity /= (double)lengthFFT;
        
        // Si está usando el iRig podemos verificar con esto si ha tocado otra nota
        if(!isAmbiental){
            peak = false;
            if(intensity > 1.2*prevIntensidad){
                prevFreq = -1;
                peak = true;
            }
        }
        prevIntensidad = intensity;
        
        // Si el sonido sobrepasa un límite de silencio, procedemos a procesar la información
        if(intensity > GetIntensityThresold()){
            
            // Especificamos cuales son las notas a buscar
            double* aBuscar = (double*)malloc(14*sizeof(double));
            for(int i = 0; i <= 12; i++)
                aBuscar[i] = CT[[delegateLayer selectedWeapon]][i];
            aBuscar[13] = CT[0][0];
            intensity *= (double)lengthFFT;
            
            // Copiamos la FFT a un arreglo auxiliar, considerando solo hasta la maxFreq determinada
            // Se escala la magnitud a valores entre 0 y 1 (porcentaje relativo)
            double* usefulFFT = (double*)malloc(lengthUsefulFFT * sizeof(double));
            for(int i = 0; i < lengthUsefulFFT; i++){
                double scaledValue = ((double)outFFTData[i])/((double)(intensity));
                usefulFFT[i] = (scaledValue <= GetLowerPeakThresold())? (double)0 : scaledValue;
            }
            
            // Se obtienen los peaks del espectro, el proceso se hace mediante vecindad definida
            // por la variable threshold, es decir, tiene que ser máximo local en un radio
            double* filteredFFT = (double*)malloc(lengthUsefulFFT*sizeof(double));
            int32_t threshold = 3;
            for(int i = 0; i < threshold; i++){
                filteredFFT[i] = 0;
                filteredFFT[lengthUsefulFFT - 1 - i] = 0;
            }
            
            int skip = 1;
            for(int i = threshold; i < lengthUsefulFFT - 1 - threshold; i += skip){
                if(usefulFFT[i] > 0){
                    bool isMax = true;
                    
                    for(int j = -threshold; j <= threshold; j++){
                        if(j != 0 && usefulFFT[i] < usefulFFT[i+j]){
                            isMax = false;
                            break;
                        }
                    }
                    
                    if(isMax){
                        filteredFFT[i] = usefulFFT[i];
                        skip = threshold;
                        for(int k = 1; k < threshold; k++)
                            filteredFFT[i+k] = 0;
                    }
                    else{
                        filteredFFT[i] = 0;
                        skip = 1;
                    }
                }
                else{
                    filteredFFT[i] = 0;
                    skip = 1;
                }
            }
            
            // Se transforman los peaks recolectados a sus valores en frecuencia
            std::vector<double> peaks;
            peaks.push_back(CT[0][0]);
            peaks.push_back(CT[1][0]);
            for(int i = 0; i < lengthUsefulFFT - threshold - 1; i++)
                if(filteredFFT[i] > GetLowerPeakThresold())
                    peaks.push_back(((double)i)*bw);
            
            // Transformamos las frecuencias obtenidas al espectro canónico de la guitarra.
            for(int i = 0; i < peaks.size(); i++)
                for(int j = 1; j < 118; j++)
                    if(peaks[i] > GetFrequency(j) && peaks[i] < GetFrequency(j + 1)){
                        if(abs(peaks[i] - GetFrequency(j)) < abs(peaks[i] - GetFrequency(j + 1)))
                            peaks[i] = GetFrequency(j);
                        else
                            peaks[i] = GetFrequency(j+1);
                        break;
                    }
            
            // Limpieza de repetidos
            sort(peaks.begin(), peaks.end());
            peaks.erase(unique(peaks.begin(), peaks.end()), peaks.end());
            
            // Rescatamos las magnitudes por ancho de banda en cada frecuencia
            std::vector<double> peakMagn;
            for(int i = 0; i < peaks.size(); i++)
                peakMagn.push_back(double(0));
            
            for(int i = 0; i < lengthUsefulFFT - 1; i++){
                if(usefulFFT[i] > 0){
                    for(int j = 0; j < 118; j++){
                        if(((double)i)*bw > GetFrequency(j) && ((double)i)*bw < GetFrequency(j + 1)){
                            double freq = 0;
                            
                            if(abs(((double)i)*bw - GetFrequency(j)) < abs(((double)i)*bw - GetFrequency(j + 1)))
                                freq = GetFrequency(j);
                            else
                                freq = GetFrequency(j+1);
                            
                            for(int k = 0; k < peaks.size(); k++)
                                if(peaks[k] == freq){
                                    peakMagn[k] += usefulFFT[i];
                                    break;
                                }
                            break;
                        }
                    }
                }
            }
            
            // Conteo de armónicos, considerando magnitud de los armónicos
            int32_t* count;
            count = (int32_t*)malloc(14* sizeof(int32_t));
            double* countMagn;
            countMagn = (double*)malloc(14* sizeof(double));
            for (int i = 0; i < 14; i++){
                count[i] = 1;
                countMagn[i] = 0;
            	for (int k = 2; k <= 10; k++){
            		for (int m = 1; m < peaks.size(); m++){
            			if (abs(k * aBuscar[i] - peaks[m]) < peaks[m] * 0.0289){
            				count[i]++;
                            countMagn[i]+=peakMagn[m];
                            break;
                        }
                    }
                }
            }
            
            // Busqueda de la fundamental
            int maxIndexFinal = 0;
            double maxSumFinal = 0;
            for(int i = 0; i < 14; i++)
            	if(maxSumFinal < countMagn[i]){
            		maxSumFinal = countMagn[i];
            		maxIndexFinal = i;
            	}
            
            // Contamos los empates
            int32_t numberConflicts = 0;
            for(int i = 0; i < 14; i++)
            	if(i != maxIndexFinal && maxSumFinal == countMagn[i])
                    numberConflicts++;
            
            // Calculo de la diferencia
            if(maxSumFinal > 0.5 && numberConflicts == 0){
                currentFrequency = aBuscar[maxIndexFinal];
                if(prevFreq != currentFrequency && currentFrequency > 0){
                    if(currentFrequency == CT[0][0]){ // Verificamos si ha tocado la 6ta cuerda al aire
                        if(silence && count[13] > 7){
                            [delegateLayer weaponChange];
                            silence = false;
                        }
                    }else{                            // Verificamos si tocó alguna otra cuerda
                        if(!isAmbiental && maxSumFinal > 0.6 && peak){
                            [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                            silence = false;
                        }else if (isAmbiental && silence && count[maxIndexFinal] > 6){
                            [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                            silence = false;
                        }
                    }
                    prevFreq = currentFrequency;
                }
            } else
                prevFreq = -1;
            
            // Se libera la data
            free(aBuscar);
            free(usefulFFT);
            free(filteredFFT);
            free(count);
            free(countMagn);
        }
        else{
            silence = true;
            prevFreq = -1;
        }
        
        // GOGOGOGOGO (dejamos que se recupere más audio)
        OSAtomicDecrement32Barrier(&mHasAudioData);
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
		mAudioBufferCurrentIndex = 0;
		return true;
	}
	else if (mNeedsAudioData == 0)
    {
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
    }
	return false;
}

double FFTBufferManager::GetFrequency(int gIndex)
{
    return guitarFrequencySpectrum[gIndex - 1];
}

void FFTBufferManager::RegisterDelegate(HelloWorldLayer *layer){
    delegateLayer = layer;
    printf("Registered a Delegated HelloWorldLayer\n");
}

double FFTBufferManager::GetIntensityThresold(){
    return isAmbiental? 15 : 100;
}

double FFTBufferManager::GetLowerPeakThresold(){
    return isAmbiental? 0.001 : 0.005;
}