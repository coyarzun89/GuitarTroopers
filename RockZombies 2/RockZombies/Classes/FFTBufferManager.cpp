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
                case 0: //eHigh
                    CT[0][j] = guitarFrequencySpectrum[j + 25 - 1];
                    break;
                case 1: //B
                    CT[1][j] = guitarFrequencySpectrum[j + 20 - 1];
                    break;
                case 2: //G
                    CT[2][j] = guitarFrequencySpectrum[j + 16 - 1];
                    break;
                case 3: //D
                    CT[3][j] = guitarFrequencySpectrum[j + 11 - 1];
                    break;
                case 4: //A
                    CT[4][j] = guitarFrequencySpectrum[j + 6 - 1];
                    break;
                case 5: //eLow
                    CT[5][j] = guitarFrequencySpectrum[j + 1 - 1];
                    break;
                default:
                    break;
            }
        }
    }
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
        
        // Variables Auxiliares
        int lengthFFT = mNumberFrames / 2;
        double maxFreq = 4804.6875;
        double duration = ((double)mNumberFrames / (double)mSampleRate);
        double bw = ((double)mSampleRate / (double)mNumberFrames);
        int lengthUsefulFFT = (int)(maxFreq*duration);
        
        // Cálculo de la intensidad promedio de la señal
        double intensidad = 0;
        for(int i = 0; i < lengthFFT - 1; i++)
            intensidad += outFFTData[i];
        intensidad /= (double)lengthFFT;
        
        //printf("%lf\n", bw);
        
        // 35 con el iRig
        // 100 ambiente leve ruido, guitarra electrica
        if(intensidad > 25){
            double* aBuscar = (double*)malloc(14*sizeof(double));
            for(int i = 0; i <= 12; i++)
                aBuscar[i] = CT[0][i];
            aBuscar[13] = CT[5][0];
            
            intensidad *= (double)lengthFFT;
            
            // Copiamos la FFT a un arreglo auxiliar, considerando solo hasta la maxFreq determinada
            // Se escala la magnitud a valores entre 0 y 1
            double* result = (double*)malloc(lengthUsefulFFT * sizeof(double));
            //std::vector<double> result;
            for(int i = 0; i < lengthUsefulFFT; i++){
                double value = ((double)outFFTData[i])/((double)(intensidad));
                result[i] = (/*i <= 5 || */value <= 0.005)? (double)0 : value;
                //printf("%lf\t", result[i]);
            }
            //printf("\n");
            
            
            
            // Se obtienen los peaks del espectro, el proceso se hace mediante vecindad definida
            // por la variable threshold, es decir, tiene que ser máximo local en un radio
            double* sen2 = (double*)malloc(lengthUsefulFFT*sizeof(double));
            int32_t threshold = 4;
            for(int i = 0; i < threshold; i++){
                sen2[i] = 0;
                sen2[lengthUsefulFFT - 1 - i] = 0;
            }
            
            int skip = 1;
            for(int i = threshold; i < lengthUsefulFFT - 1 - threshold; i += skip){
                if(result[i] > 0){
                    bool isMax = true;
                    
                    for(int j = -threshold; j <= threshold; j++){
                        if(j != 0 && result[i] < result[i+j]){
                            isMax = false;
                            break;
                        }
                    }
                    
                    if(isMax){
                        sen2[i] = result[i];
                        skip = threshold;
                        //printf("%d\t", i);
                    }
                }else{
                    sen2[i] = 0;
                    skip = 1;
                }
            }
            //printf("\n");
            
            // Se transforman los peaks recolectados a sus valores en frecuencia
            std::vector<double> h;
            h.push_back(((double)8)*bw);
            h.push_back(((double)10)*bw);
            for(int i = 0; i < lengthUsefulFFT - threshold - 1; i++)
                if(sen2[i] > 0.005)
                    h.push_back(((double)i)*bw);
            
            //printf("\n");
            
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
            
            //for(int i = 0; i < h.size(); i++)
            //    printf("%.1f ", h[i]);
            //printf("\n");
            
            // Conteo de armonicos
            /*int32_t* count;
             count = (int32_t*)malloc(h.size()* sizeof(int32_t));
             for (int i = 0; i < h.size(); i++){
             count[i] = 1;
             for (int k = 2; k <= 20; k++){
             for (int m = 1; m < h.size(); m++){
             if (abs(k * h[i] - h[m]) < h[m] * 0.0289){
             count[i]++;
             break;
             }
             
             }
             if (h[i] < 110 && k == 4 && count[i] < 4){
             count[i] = 0;
             break;
             }else if (h[i] >= 110 && h[i] <= 165 && k == 4 && count[i] < 4){
             count[i] = 0;
             break;
             }else if(h[i] > 165 && h[i] <= 660 && k == 4 && count[i] < 4){
             count[i] = 0;
             break;
             }else if(h[i] > 660){
             count[i] = 0;
             break;
             }
             }
             }*/
            
            int32_t* count;
            count = (int32_t*)malloc(14* sizeof(int32_t));
            for (int i = 0; i < 14; i++){
                count[i] = 1;
            	for (int k = 2; k <= 20; k++){
            		for (int m = 1; m < h.size(); m++){
            			if (abs(k * aBuscar[i] - h[m]) < h[m] * 0.0289){
            				count[i]++;
                            break;
                        }
                    }
                    
                    if (aBuscar[i] < 110 && k == 6 && count[i] < 6){
                        count[i] = 0;
                        break;
                    }else if (aBuscar[i] >= 110 && aBuscar[i] <= 165 && k == 3 && count[i] < 3 ){
                        count[i] = 0;
                        break;
                    }else if(aBuscar[i] > 165 && aBuscar[i] <= 660 && k == 3 && count[i] < 3){
                        count[i] = 0;
                        break;
                    }else if(aBuscar[i] > 660){
                        count[i] = 0;
                        break;
                    }
                }
            }
            
            // Busqueda de la fundametal
            int maxIndexFinal = 0;
            int maxCountFinal = -1;
            for(int i = 0; i < 14; i++)
            	if(maxCountFinal < count[i]){
            		maxCountFinal = count[i];
            		maxIndexFinal = i;
            	}
            
            int32_t numberConflicts = 0;
            for(int i = 0; i < 14; i++)
            	if(maxCountFinal == count[i])
                    numberConflicts++;
            
            // Calculo de la diferencia
            if(maxCountFinal > 2)
                currentFrequency = aBuscar[maxIndexFinal];
            else
                currentFrequency = -1;
            
            if(currentFrequency > 0 && numberConflicts < 2)
                printf("Frecuency: %.1f (%d) - %d\n", currentFrequency, maxCountFinal, numberConflicts);
            
            // Se libera la data
            free(sen2);
            free(result);
            free(count);
        }
        
        // GOGOGOGOGO
        OSAtomicDecrement32Barrier(&mHasAudioData);
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
		mAudioBufferCurrentIndex = 0;
		return true;
	}
	else if (mNeedsAudioData == 0)
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
	
	return false;
}

double FFTBufferManager::GetFrequency(int gIndex)
{
    return guitarFrequencySpectrum[gIndex - 1];
}