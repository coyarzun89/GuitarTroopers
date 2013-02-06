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

FFTBufferManager::~FFTBufferManager()
{
	free(mAudioBuffer);
	SpectrumAnalysisDestroy(mSpectrumAnalysis);
}

void FFTBufferManager::GrabAudioData(AudioBufferList *inBL)
{
	if (mAudioBufferSize < inBL->mBuffers[0].mDataByteSize)	return;
	
	UInt32 bytesToCopy = min(inBL->mBuffers[0].mDataByteSize, mAudioBufferSize - mAudioBufferCurrentIndex);
	memcpy(mAudioBuffer+mAudioBufferCurrentIndex, inBL->mBuffers[0].mData, bytesToCopy);
	
	mAudioBufferCurrentIndex += bytesToCopy / sizeof(int32_t);
	if (mAudioBufferCurrentIndex >= mAudioBufferSize / sizeof(int32_t))
	{
		OSAtomicIncrement32Barrier(&mHasAudioData);
		OSAtomicDecrement32Barrier(&mNeedsAudioData);
	}
}

Boolean	FFTBufferManager::ComputeFFT(int32_t *outFFTData)
{
	if (HasNewAudioData())
	{
        // Borramos la frecuencia anterior
        currentFrequency = -1;
        
        // Realizamos una FFT
		SpectrumAnalysisProcess(mSpectrumAnalysis, mAudioBuffer, outFFTData, false);
        
        // Cálculo de la intensidad promedio de la señal
        double intensidad = 0;
        for(int i = 0; i < lengthFFT - 1; i++)
            intensidad += outFFTData[i];
        intensidad /= (double)lengthFFT;
        
        peak = false;
        // Si está usando el iRig podemos verificar con esto si ha tocado otra nota
        if(!isAmbiental){
            if(intensidad > 1.2*prevIntensidad){
                prevFreq = -1;
                peak = true;
            }
        }
        prevIntensidad = intensidad;
        
        if(intensidad > GetIntensityThresold())
        {
            double* aBuscar = (double*)malloc(14*sizeof(double));
            for(int i = 0; i <= 12; i++)
                aBuscar[i] = CT[[delegateLayer selectedWeapon]][i];
            aBuscar[13] = CT[0][0];
            intensidad *= (double)lengthFFT;
            
            // Copiamos la FFT a un arreglo auxiliar, considerando solo hasta la maxFreq determinada
            // Se escala la magnitud a valores entre 0 y 1
            double* result = (double*)malloc(lengthUsefulFFT * sizeof(double));
            double algo = 0;

            for(int i = 0; i < lengthUsefulFFT; i++)
            {
                double value = ((double)outFFTData[i])/((double)(intensidad));
                result[i] = (value <= GetLowerPeakThresold())? (double)0 : value;
                algo += value;
            }
            
            // Se obtienen los peaks del espectro, el proceso se hace mediante vecindad definida
            // por la variable threshold, es decir, tiene que ser máximo local en un radio
            double* sen2 = (double*)malloc(lengthUsefulFFT*sizeof(double));
            int32_t threshold = 3;
            for(int i = 0; i < threshold; i++)
            {
                sen2[i] = 0;
                sen2[lengthUsefulFFT - 1 - i] = 0;
            }
            
            int skip = 1;
            for(int i = threshold; i < lengthUsefulFFT - 1 - threshold; i += skip)
            {
                if(result[i] > 0)
                {
                    bool isMax = true;
                    
                    for(int j = -threshold; j <= threshold; j++)
                    {
                        if(j != 0 && result[i] < result[i+j])
                        {
                            isMax = false;
                            break;
                        }
                    }
                    
                    if(isMax)
                    {
                        sen2[i] = result[i];
                        skip = threshold;
                        for(int k = 1; k < threshold; k++)
                            sen2[i+k] = 0;
                    }
                    else
                    {
                        sen2[i] = 0;
                        skip = 1;
                    }
                }
                else
                {
                    sen2[i] = 0;
                    skip = 1;
                }
            }
            
            /*for(int i = 0; i < lengthUsefulFFT - threshold - 1; i++)
                printf("%lf\t", sen2[i]);
            printf("\n");*/
            
            // Se transforman los peaks recolectados a sus valores en frecuencia
            std::vector<double> h;
            h.push_back(CT[0][0]);
            h.push_back(CT[1][0]);
            for(int i = 0; i < lengthUsefulFFT - threshold - 1; i++)
                if(sen2[i] > GetLowerPeakThresold())
                    h.push_back(((double)i)*bw);
            
            // Transformamos las frecuencias obtenidas al espectro canónico de la guitarra.
            for(int i = 0; i < h.size(); i++)
                for(int j = 1; j < 118; j++)
                    if(h[i] > GetFrequency(j) && h[i] < GetFrequency(j + 1)){
                        if(abs(h[i] - GetFrequency(j)) < abs(h[i] - GetFrequency(j + 1)))
                            h[i] = GetFrequency(j);
                        else
                            h[i] = GetFrequency(j+1);
                        break;
                    }
            
            // Limpieza de repetidos
            sort(h.begin(), h.end());
            h.erase(unique(h.begin(), h.end()), h.end());
            
            // Rescatamos las magnitudes por ancho de banda en cada frecuencia
            std::vector<double> hMagn;
            for(int i = 0; i < h.size(); i++)
                hMagn.push_back(double(0));
            
            for(int i = 0; i < lengthUsefulFFT - 1; i++){
                if(result[i] > 0){
                    for(int j = 0; j < 118; j++){
                        if(((double)i)*bw > GetFrequency(j) && ((double)i)*bw < GetFrequency(j + 1)){
                            double freq = 0;
                            
                            if(abs(((double)i)*bw - GetFrequency(j)) < abs(((double)i)*bw - GetFrequency(j + 1)))
                                freq = GetFrequency(j);
                            else
                                freq = GetFrequency(j+1);
                            
                            for(int k = 0; k < h.size(); k++)
                                if(h[k] == freq){
                                    hMagn[k] += result[i];
                                    break;
                                }
                            break;
                        }
                    }
                }
            }
            
            //for(int i = 0; i < hMagn.size(); i++)
            //    printf("%lf: %lf\n", h[i], hMagn[i]);
            //printf("\n");
            
            // Conteo de armónicos
            int32_t* count;
            count = (int32_t*)malloc(14* sizeof(int32_t));
            double* countMagn;
            countMagn = (double*)malloc(14* sizeof(double));
            for (int i = 0; i < 14; i++)
            {
                count[i] = 1;
                countMagn[i] = 0;
            	for (int k = 2; k <= 10; k++)
                {
            		for (int m = 1; m < h.size(); m++)
                    {
            			if (abs(k * aBuscar[i] - h[m]) < h[m] * 0.0289)
                        {
            				count[i]++;
                            countMagn[i]+=hMagn[m];
                            break;
                        }
                    }
                    
                    /*if (aBuscar[i] < 110){
                        if (isAmbiental && k == 3 && count[i] < 3) {
                            count[i] = 0;
                            break;
                        }else
                     
                        if(!isAmbiental && k == 4 && count[i] < 4){
                            count[i] = 0;
                            break;
                        }
                    }
                    else if (aBuscar[i] >= 110 && aBuscar[i] <= 165) // 5 con el iRig
                    {
                        if (isAmbiental && k == 3 && count[i] < 3) {
                            count[i] = 0;
                            break;
                        }else if(!isAmbiental && k == 3 && count[i] < 3){
                            count[i] = 0;
                            break;
                        }
                    }
                    else if(aBuscar[i] > 165 && aBuscar[i] <= 660) // 4 con el iRig
                    {
                        if (isAmbiental && k == 3 && count[i] < 3) {
                            count[i] = 0;
                            break;
                        }else if(!isAmbiental && k == 3 && count[i] < 3){
                            count[i] = 0;
                            break;
                        }
                    }
                    else if(aBuscar[i] > 660)
                    {
                        count[i] = 0;
                        break;
                    }*/
                }
            }
            
            //printf("El valor es %d.\n", count[13]);
            
            // Busqueda de la fundametal
            int maxIndexFinal = 0;
            double maxSumFinal = 0;
            for(int i = 0; i < 14; i++)
            	if(maxSumFinal < countMagn[i])
                {
            		maxSumFinal = countMagn[i];
            		maxIndexFinal = i;
            	}
            
            // Contamos los empates (no se hace nada si hay conflicto)
            int32_t numberConflicts = 0;
            
            for(int i = 0; i < 14; i++)
            	if(maxSumFinal == countMagn[i])
                    numberConflicts++;
            
            // Calculo de la diferencia
            if(maxSumFinal > 0.5)
                currentFrequency = aBuscar[maxIndexFinal];
            else
                currentFrequency = -1;
            
            
            printf("%lf\n", maxSumFinal);
            
            if(numberConflicts < 2 && prevFreq != currentFrequency){
                if(currentFrequency == CT[0][0]) // Verificamos si ha tocado la 6ta cuerda al aire
                {
                    if(silence && count[13] > 7){
                        [delegateLayer weaponChange];
                        silence = false;
                    }
                }
                else if(currentFrequency != CT[0][0] && currentFrequency > 0)
                {
                    if(!isAmbiental && maxSumFinal > 0.6){
                        [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                        silence = false;
                    }
                    else if (isAmbiental && silence && count[maxIndexFinal] > 6)
                    {
                        [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                    }
                
                }
            }
            prevFreq = currentFrequency;
            
            // Se libera la data
            free(sen2);
            free(result);
            free(count);
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