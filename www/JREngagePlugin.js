/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright (c) 2012, Janrain, Inc.

 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution.
 * Neither the name of the Janrain, Inc. nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 File:   JREngagePlugin.js
 Author: Lilli Szafranski - lilli@janrain.com, lillialexis@gmail.com
 Date:   Wednesday, January 4th, 2012
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

 /** 2013-11-01  Full rewriting to match phonegap 3 requirements (Iurii Kyian) */

var exec = require('cordova/exec');

module.exports = {
  print : function(message, success, fail){
    exec(success, fail, 'JREngagePlugin', 'print', [message]);
  },
  initialize : function(appid, tokenurl, success, fail){
    exec(success, fail, 'JREngagePlugin', 'initializeJREngage', [appid, tokenurl]);
  },
  showAuthentication : function(success, fail){
    exec(success, fail, 'JREngagePlugin', 'showAuthenticationDialog', []);
  },
  showSharing : function(activity, success, fail){
    exec(success, fail, 'JREngagePlugin', 'showSharingDialog', [activity]);
  },
  //error codes
  JREngagePhonegapError                :  -1,
  JRUrlError                           : 100,
  JRDataParsingError                   : 101,
  JRJsonError                          : 102,
  JRConfigurationInformationError      : 103,
  JRSessionDataFinishGetProvidersError : 104,
  JRDialogShowingError                 : 105,
  JRProviderNotConfiguredError         : 106,
  JRMissingAppIdError                  : 107,
  JRGenericConfigurationError          : 108,
  JRAuthenticationFailedError          : 200,
  JRAuthenticationTokenUrlFailedError  : 201,
  JRAuthenticationCanceled             : 202,
  JRPublishFailedError                 : 300,
  JRPublishErrorActivityNil            : 301,
  JRPublishErrorBadActivityJson        : 302,
  JRPublishCanceledError               : 303,
  JRPublishErrorBadConnection          : 304,
  JRPublishErrorMissingParameter       : 305,
  JRPublishErrorMissingApiKey          : 306,
  JRPublishErrorCharacterLimitExceeded : 307,
  JRPublishErrorFacebookGeneric        : 308,
  JRPublishErrorInvalidFacebookSession : 309,
  JRPublishErrorInvalidFacebookMedia   : 310,
  JRPublishErrorTwitterGeneric         : 311,
  JRPublishErrorDuplicateTwitter       : 312,
  JRPublishErrorLinkedInGeneric        : 313,
  JRPublishErrorMyspaceGeneric         : 314,
  JRPublishErrorYahooGeneric           : 315,
  JRPublishErrorFeedActionRequestLimit : 316
};

