/*

    File: FFTBufferManager.cpp
Abstract: This class manages buffering and computation for FFT analysis on input audio data. The methods provided are used to grab the audio, buffer it, and perform the FFT when sufficient data is available
 Version: 1.21

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2010 Apple Inc. All Rights Reserved.


*/

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
        // Realizamos una FFT
		SpectrumAnalysisProcess(mSpectrumAnalysis, mAudioBuffer, outFFTData, false);
        
        // Variables Auxiliares
        double num = 4804.6875;
        double duration = ((double)mNumberFrames / (double)mSampleRate);
        double bw = ((double)mSampleRate / (double)mNumberFrames) / 2;
        
        long promedio = 0;
        for(int i = 0; i < mNumberFrames/2; i++)
            promedio += outFFTData[i];
        
        promedio = promedio / mNumberFrames / 2;
        currentFrequency = -1;
        
        // 35 con el iRig
        if(promedio > 35){
            // Se trunca la data, ya que la primera parte del espectro no sirve.
            outFFTData[0] = 0;
            outFFTData[1] = 0;
            outFFTData[2] = 0;
            outFFTData[3] = 0;
            outFFTData[4] = 0;
            outFFTData[5] = 0;
            outFFTData[6] = 0;
            
            // Variables auxiliares.
            int n2 = (int)(num*duration);
            int32_t* result;
            result = (int32_t*)malloc(n2* sizeof(int32_t));
            
            // Se trunca la data, ya que la primera parte del espectro no sirve.
            for(int i = 0; i < n2; i++)
                if(i <= 7)
                    result[i] = 0;
                else
                    result[i] = outFFTData[i];
            
            // Se obtiene el máximo peak del espectro.
            int32_t maxIndex = 0;
            for(int i = 0; i < mNumberFrames/2; i++)
                if(outFFTData[maxIndex] < outFFTData[i])
                    maxIndex = i;
            
            
            
            //Se obtienen los peaks del espectro.
            int32_t* sen2;
            sen2 = (int32_t*)malloc(n2*sizeof(int32_t));
            sen2[0] = 0;
            sen2[n2-1] = 0;
            for(int i = 1; i < n2 - 1; i++)
                if(result[i] > result[i-1] && result[i] > result[i+1]){
                    sen2[i] = result[i];
                    if(sen2[i] < (int32_t)(0.3 * (float)outFFTData[maxIndex]))
                        sen2[i] = 0;
                }
            
            //currentFrequency = maxIndex * bw;
            
            // Se transforman los peaks recolectados a sus valores en frecuencia
            std::vector<double> h;
            for(int i = 0; i < n2; i++){
                if(sen2[i] > 0){
                    bool encontrado = false;
                    for(int j = 0; j < h.size(); j++)
                        if(h[j] == ((float)(i+1))*bw)
                            encontrado = true;
                    if(!encontrado)
                        h.push_back(((float)(i+1))*bw);
                }
            }
            h.push_back( ((double)440) / pow(2, ((float)29 / 12)));
            
            //currentFrequency = h.size();
            
            
            // Transformamos las frecuencias obtenidas al espectro canónico de la guitarra.
            for(int i = 0; i < h.size(); i++){
                int a3 = 0;
                for(int j = 1; j < 118; j++){
                    if(a3 < 1 && abs(h[i] - GetFrequency(j)) < abs(h[i] - GetFrequency(j + 1))){
                        replace(h.begin(), h.end(), h[i], GetFrequency(j));
                        a3 = 2;
                    }
                }
            }
            
            // Limpieza de repetidos
            sort(h.begin(), h.end());
            h.erase(unique(h.begin(), h.end()), h.end());
            
            // Busqueda de los peaks más significativo
            int count[] = {0,0,0};
            double maxFreq[] = {0.0, 0.0, 0.0};
            int maxIndexFreq[] = {0, 0, 0};
            for (int i = 1; i < n2 - 1; i++){
                if(maxFreq[0] < result[i]){
                	maxFreq[2] = maxFreq[1];
                	maxFreq[1] = maxFreq[0];
                	maxFreq[0] = result[i];
                	maxIndexFreq[2] = maxIndexFreq[1];
                	maxIndexFreq[1] = maxIndexFreq[0];
                	maxIndexFreq[0] = i;
                }else if(maxFreq[1] < result[i]){
                	maxFreq[2] = maxFreq[1];
                	maxFreq[1] = result[i];
                	maxIndexFreq[2] = maxIndexFreq[1];
                	maxIndexFreq[1] = i;
                }else if(maxFreq[2] < result[i]){
                	maxFreq[2] = result[i];
                	maxIndexFreq[2] = i;
                }
	    	}
            maxFreq[0] = maxIndexFreq[0] * bw;
            maxFreq[1] = maxIndexFreq[1] * bw;
            maxFreq[2] = maxIndexFreq[2] * bw;
            
            // Conteo de armonicos
            for (int i = 0; i < 3; i++)
            	for (int k = 1; k <= 12; k++)
            		for (int m = 1; m < h.size(); m++)
            			if (abs(k * maxFreq[i] - h[m]) < h[m] * 0.0289)
            				count[i]++;
            
            // Busqueda de la fundametal
            int maxIndexFinal = 0;
            int maxCountFinal = 0;
            for(int i = 0; i < 3; i++)
            	if(maxCountFinal < count[i]){
            		maxCountFinal = count[i];
            		maxIndexFinal = i;
            	}
            
            // Calculo de la diferencia
            if(maxCountFinal > 3)
                currentFrequency = maxFreq[maxIndexFinal];
            else
                currentFrequency = -1;
            
            if(currentFrequency == 330)
                currentFrequency = 80085;
            
            // Se libera la data
            free(sen2);
            //free(diffsen2);
            free(result);
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