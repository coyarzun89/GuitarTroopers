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
            for(int i = 0; i < lengthUsefulFFT; i++)
            {
                double value = ((double)outFFTData[i])/((double)(intensidad));
                result[i] = (value <= GetLowerPeakThresold())? (double)0 : value;
            }
            
            // Se obtienen los peaks del espectro, el proceso se hace mediante vecindad definida
            // por la variable threshold, es decir, tiene que ser máximo local en un radio
            double* sen2 = (double*)malloc(lengthUsefulFFT*sizeof(double));
            int32_t threshold = 4;
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
                    }
                }
                else
                {
                    sen2[i] = 0;
                    skip = 1;
                }
            }
            
            // Se transforman los peaks recolectados a sus valores en frecuencia
            std::vector<double> h;
            h.push_back(((double)8)*bw);
            h.push_back(((double)10)*bw);
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
            
            for(int i = 0; i < h.size(); i++)
                printf("%lf\t", h[i]);
            printf("\n");
            
            // Conteo de armónicos
            int32_t* count;
            count = (int32_t*)malloc(14* sizeof(int32_t));
            for (int i = 0; i < 14; i++)
            {
                count[i] = 1;
            	for (int k = 2; k <= 10; k++)
                {
            		for (int m = 1; m < h.size(); m++)
                    {
            			if (abs(k * aBuscar[i] - h[m]) < h[m] * 0.0289)
                        {
            				count[i]++;
                            break;
                        }
                    }
                    
                    if (aBuscar[i] < 110){
                        if (isAmbiental && k == 4 && count[i] < 4) {
                            count[i] = 0;
                            break;
                        }else if(!isAmbiental && k == 4 && count[i] < 4){
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
                    }
                }
            }
            
            printf("El valor es %d.\n", count[10]);
            
            // Busqueda de la fundametal
            int maxIndexFinal = 0;
            int maxCountFinal = -1;
            for(int i = 0; i < 14; i++)
            	if(maxCountFinal < count[i])
                {
            		maxCountFinal = count[i];
            		maxIndexFinal = i;
            	}
            
            // Contamos los empates (no se hace nada si hay conflicto)
            int32_t numberConflicts = 0;
            for(int i = 0; i < 14; i++)
            	if(maxCountFinal == count[i])
                    numberConflicts++;
            
            // Calculo de la diferencia
            if(maxCountFinal > 2)
                currentFrequency = aBuscar[maxIndexFinal];
            else
                currentFrequency = -1;
            
            if(numberConflicts < 2){
                if(silence && currentFrequency == CT[0][0]) // Verificamos si ha tocado la 6ta cuerda al aire
                {
                    if((isAmbiental /*&& maxCountFinal > h.size()/2*/) || !isAmbiental){
                        [delegateLayer weaponChange];
                        silence = false;
                    }
                }
                else if(currentFrequency != CT[0][0] && currentFrequency > 0)
                {
                    if( (peak && !isAmbiental && maxCountFinal > (h.size()-1)/2)){
                        [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                    }
                    else if(!peak && !isAmbiental && maxCountFinal > 0.9*(h.size()-1))
                    {
                        [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                    }
                    else if (maxCountFinal > 0.8*(h.size()-1) && isAmbiental)
                    {
                        [delegateLayer shootWithFret:[NSNumber numberWithInt:maxIndexFinal]];
                    }
                
                }
            }
            
            // Se libera la data
            free(sen2);
            free(result);
            free(count);
        }
        else{
            silence = true;
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
    return isAmbiental? 8 : 100;
}

double FFTBufferManager::GetLowerPeakThresold(){
    return isAmbiental? 0.01 : 0.005;
}