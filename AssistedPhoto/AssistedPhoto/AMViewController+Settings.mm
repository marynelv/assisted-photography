//
//  AMViewController+Settings.m
//  AudiballMix
//
//    Created by Marynel Vazquez on 9/20/11.
//    Copyright 2011 Carnegie Mellon University.
//
//    This work was developed under the Rehabilitation Engineering Research 
//    Center on Accessible Public Transportation (www.rercapt.org) and is funded 
//    by grant number H133E080019 from the United States Department of Education 
//    through the National Institute on Disability and Rehabilitation Research. 
//    No endorsement should be assumed by NIDRR or the United States Government 
//    for the content contained on this code.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.
//

#import "AMViewController+Settings.h"
#import "AMViewController+TargetSelection.h"

#define PrefLogStr(p,v) NSLog( @"Pref(%@) = %@", p, v)
#define PrefLogFloat(p,v) NSLog( @"Pref(%@) = %.2f", p, v)
#define PrefLogInt(p,v) NSLog( @"Pref(%@) = %d", p, v)

@implementation AMViewController (Settings)

/**
    Load user settings
 */
-(void) loadSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (defaults)
    {
        
        // target estimator type
        int targetEstimatorType = [AMViewController 
                                             loadMultivalueSetting:@"target_estimator_preference" 
                                                                         orSetDefault:1
                                                                      usingDefaults:defaults];
        [self setUpNewTargetEstimator:(TargetEstimatorType)targetEstimatorType];
        
        // acceptance radius
        CGFloat acceptanceRadius = [[AMViewController loadStringSetting:@"target_acceptance_radius_preference" 
                                                           orSetDefault:@"20"
                                                          usingDefaults:defaults] floatValue];
        [self.targetEstimator setAcceptanceRadius:acceptanceRadius];
        
        // sound type
        int soundType = [AMViewController loadMultivalueSetting:@"sound_type_preference" 
                                                   orSetDefault:3
                                                  usingDefaults:defaults];
        [self.targetEstimator setUpAudioFeedback:(AudioType)soundType];
        [self.targetEstimator start];
        
    }
}

/**
    Load string setting
    @param identifier setting identifier
    @param defaultVal default value (used if the setting hasn't been defined)
    @param defaults user defaults
    @return string setting
 */
+(NSString*) loadStringSetting:(NSString *)identifier orSetDefault:(NSString*)defaultVal usingDefaults:(NSUserDefaults*)defaults
{
    NSString *str;
    if (![defaults objectForKey:identifier]) // no preference, so we set the default
    {   
        [defaults setObject:defaultVal forKey:identifier];
        if (![defaults synchronize]) DebugLog(@"Could not synchronize user defaults for %@.", identifier);
        str = defaultVal;
    }
    else
    {
        str = [defaults stringForKey:identifier];
    }
    PrefLogStr(identifier,str); 
    return str;
}

/**
    Load boolean setting
    @param identifier setting identifier
    @param defaultVal default value (used if the setting hasn't been defined)
    @param defaults user defaults
    @return boolean setting
 */
+(BOOL) loadBoolSetting:(NSString *)identifier orSetDefault:(BOOL)defaultVal usingDefaults:(NSUserDefaults*)defaults
{
    BOOL boolean;
    if (![defaults objectForKey:identifier]) // no preference, so we set the default
    {   
        [defaults setBool:defaultVal forKey:identifier];
        boolean = defaultVal;
        if (![defaults synchronize]) DebugLog(@"Could not synchronize user defaults for %@.", identifier);
    }
    else
    {
        boolean = [defaults boolForKey:identifier];
    }
    PrefLogInt(identifier,boolean); 
    return boolean;
}

/**
    Load multivalue setting
    @param identifier setting identifier
    @param defaultVal default value (used if the setting hasn't been defined)
    @param defaults user defaults
    @return setting value
 */
+(int) loadMultivalueSetting:(NSString *)identifier orSetDefault:(int)defaultVal usingDefaults:(NSUserDefaults*)defaults
{
    int value;
    if (![defaults objectForKey:identifier]) // no preference, so we set the default
    {   
        [defaults setInteger:defaultVal forKey:identifier];
        if (![defaults synchronize]) DebugLog(@"Could not synchronize user defaults for %@.", identifier);
        value = defaultVal;
    }
    else
    {
        value = [defaults integerForKey:identifier];
    }
    PrefLogInt(identifier,value); 
    return value;
}

@end
