//
//  FliteTTS.m
//  iPhone Text To Speech based on Flite
//
//  Copyright (c) 2010 Sam Foster
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Author: Sam Foster <samfoster@gmail.com> <http://cmang.org>
//  Copyright 2010. All rights reserved.
//

#import "TTSEngine.h"
#import "flite.h"

cst_voice *register_cmu_us_kal();
cst_voice *register_cmu_us_kal16();
cst_voice *register_cmu_us_rms();
cst_voice *register_cmu_us_awb();
cst_voice *register_cmu_us_slt();
cst_wave *sound;
cst_voice *voice;

@implementation TTSEngine

-(id)init
{
    self = [super init];
	flite_init();
	[self setVoice:@"cmu_us_slt"];
    return self;
}

+ (instancetype)tts
{
    static dispatch_once_t once;
    static id tts;
    
    dispatch_once(&once, ^{
        tts = [[self alloc] init];
    });
    
    return tts;
}

-(void)speakText:(NSString *)text
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        if (![self runGoogleTTS:text]) {
            [self runFliteTTS: text];
        }
    });
    
}

- (BOOL)runGoogleTTS:(NSString *)text {
    NSLog(@"GoogleTTS is executed");
    NSString *queryTTS = [text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *linkTTS = [NSString stringWithFormat:@"http://translate.google.com/translate_tts?tl=en&q=%@",queryTTS];
    
    NSData *dataTTS = [NSData dataWithContentsOfURL:[NSURL URLWithString:linkTTS]];
    
    if (dataTTS != nil){
        NSError* err;
        audioPlayer = [[AVAudioPlayer alloc] initWithData:dataTTS error:&err];
        if (err){
            NSLog(@"GoogleTTS Error: %@", [err localizedDescription]);
        }
        [audioPlayer play];
    }
    
    return (dataTTS != nil);
}

-(void)runFliteTTS: (NSString*)text {
    NSLog(@"FliteTTS is executed");
    NSMutableString *cleanString;
    cleanString = [NSMutableString stringWithString:@""];
    if([text length] > 1)
    {
        int x = 0;
        while (x < [text length])
        {
            unichar ch = [text characterAtIndex:x];
            [cleanString appendFormat:@"%c", ch];
            x++;
        }
    }
    if(cleanString == nil)
    {	// string is empty
        cleanString = [NSMutableString stringWithString:@""];
    }
    sound = flite_text_to_wave([cleanString UTF8String], voice);
    
	// copy sound into soundObj
    soundObj = [[NSMutableData alloc] init];
    cst_wave_to_nsdata(sound, soundObj);
    

    NSError* err;
    audioPlayer = [[AVAudioPlayer alloc] initWithData:soundObj error:&err];
    if (err){
        NSLog(@"FliteTTS Error: %@", [err localizedDescription]);
    }
    [audioPlayer play];
    
    delete_wave(sound);

}

// this is a copy of cst_wave_save_riff,
// but writes to NSMutableData instead of a file.
int cst_wave_to_nsdata(cst_wave *w, NSMutableData *data)
{
    char *info;
    short d_short;
    int d_int;
    int num_bytes;
    
    info = "RIFF";
    [data appendBytes:info length:4];
    
    num_bytes = (cst_wave_num_samples(w)
                 * cst_wave_num_channels(w)
                 * sizeof(short)) + 8 + 16 + 12; /* num bytes in whole file */
    
    if (CST_BIG_ENDIAN) num_bytes = SWAPINT(num_bytes);
    [data appendBytes:&num_bytes length:4];
    info = "WAVE";
    [data appendBytes:info length:4];
    info = "fmt ";
    [data appendBytes:info length:4];
    num_bytes = 16;                   /* size of header */
    if (CST_BIG_ENDIAN) num_bytes = SWAPINT(num_bytes);
    [data appendBytes:&num_bytes length:4];
    d_short = RIFF_FORMAT_PCM;        /* sample type */
    if (CST_BIG_ENDIAN) d_short = SWAPSHORT(d_short);
    [data appendBytes:&d_short length:2];
    d_short = cst_wave_num_channels(w); /* number of channels */
    if (CST_BIG_ENDIAN) d_short = SWAPSHORT(d_short);
    [data appendBytes:&d_short length:2];
    d_int = cst_wave_sample_rate(w);  /* sample rate */
    if (CST_BIG_ENDIAN) d_int = SWAPINT(d_int);
    [data appendBytes:&d_int length:4];
    d_int = (cst_wave_sample_rate(w)
             * cst_wave_num_channels(w)
             * sizeof(short));        /* average bytes per second */
    if (CST_BIG_ENDIAN) d_int = SWAPINT(d_int);
    [data appendBytes:&d_int length:4];
    d_short = (cst_wave_num_channels(w)
               * sizeof(short));      /* block align */
    if (CST_BIG_ENDIAN) d_short = SWAPSHORT(d_short);
    [data appendBytes:&d_short length:2];
    d_short = 2 * 8;                  /* bits per sample */
    if (CST_BIG_ENDIAN) d_short = SWAPSHORT(d_short);
    [data appendBytes:&d_short length:2];
    info = "data";
    [data appendBytes:info length:4];
    d_int = (cst_wave_num_channels(w)
             * cst_wave_num_samples(w)
             * sizeof(short));	      /* bytes in data */
    if (CST_BIG_ENDIAN) d_int = SWAPINT(d_int);
    [data appendBytes:&d_int length:4];
    
    if (CST_BIG_ENDIAN)
    {
        short *xdata = cst_alloc(short,cst_wave_num_channels(w)*
                                 cst_wave_num_samples(w));
        memmove(xdata,cst_wave_samples(w),
                sizeof(short)*cst_wave_num_channels(w)*
                cst_wave_num_samples(w));
        swap_bytes_short(xdata,
                         cst_wave_num_channels(w)*
                         cst_wave_num_samples(w));
        
        [data appendBytes:xdata length:sizeof(short) * cst_wave_num_channels(w)*cst_wave_num_samples(w)];
        
        cst_free(xdata);
    }
    else
    {
        [data appendBytes:cst_wave_samples(w) length:sizeof(short) * cst_wave_num_channels(w)*cst_wave_num_samples(w)];
    }
    
    // TODO: check data.length to make sure math is right?
    return 0;
}



-(void)setPitch:(float)pitch variance:(float)variance speed:(float)speed
{
	feat_set_float(voice->features,"int_f0_target_mean", pitch);
	feat_set_float(voice->features,"int_f0_target_stddev",variance);
	feat_set_float(voice->features,"duration_stretch",speed); 
}

-(void)setVoice:(NSString *)voicename
{
	if([voicename isEqualToString:@"cmu_us_kal"]) {
		voice = register_cmu_us_kal();
	}
	else if([voicename isEqualToString:@"cmu_us_kal16"]) {
		voice = register_cmu_us_kal16();
	}
	else if([voicename isEqualToString:@"cmu_us_rms"]) {
		voice = register_cmu_us_rms();
	}
	else if([voicename isEqualToString:@"cmu_us_awb"]) {
		voice = register_cmu_us_awb();
	}
	else if([voicename isEqualToString:@"cmu_us_slt"]) {
		voice = register_cmu_us_slt();
	}
}

-(void)stopTalking
{
	[audioPlayer stop];
}

@end
