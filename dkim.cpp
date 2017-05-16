/*****************************************************************************
*  Copyright 2005 Alt-N Technologies, Ltd.
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
*  This code incorporates intellectual property owned by Yahoo! and licensed
*  pursuant to the Yahoo! DomainKeys Patent License Agreement.
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*
*****************************************************************************/

#include "dkim.h"
#include "dkimsign.h"
#include "dkimverify.h"
#include <string.h>

#define DKIMID ('D' | 'K'<<8 | 'I'<<16 | 'M'<<24)
/* taken from removed file "ressource.h" */
#ifdef VERSION
#define VERSION_STRING VERSION
#else
#define VERSION_STRING "1.0.23"
#endif

static void InitContext( DKIMContext* pContext, bool bSign, void* pObject )
{
  pContext->reserved1 = DKIMID;
  pContext->reserved2 = bSign ? 1 : 0;
  pContext->reserved3 = pObject;
}

static void* ValidateContext( DKIMContext* pContext, bool bSign )
{
  if( pContext->reserved1 != DKIMID )
    return NULL;

  if( pContext->reserved2 != (unsigned int)(bSign ? 1 : 0) )
    return NULL;

  return pContext->reserved3;
}

int DKIM_CALL DKIMSignInit( DKIMContext* pSignContext, DKIMSignOptions* pOptions )
{
  int nRet = DKIM_OUT_OF_MEMORY;

  CDKIMSign* pSign = new CDKIMSign;

  if( pSign )
  {
    nRet = pSign->Init( pOptions );
    if( nRet != DKIM_SUCCESS )
      delete pSign;
  }

  if( nRet == DKIM_SUCCESS ) { InitContext( pSignContext, true, pSign ); }
  return nRet;
}

int DKIM_CALL DKIMSignProcess( DKIMContext* pSignContext, char* szBuffer, int nBufLength )
{
  CDKIMSign* pSign = (CDKIMSign*)ValidateContext( pSignContext, true );

  if( pSign ) { return pSign->Process( szBuffer, nBufLength, false ); }
  return DKIM_INVALID_CONTEXT;
}

/*
int DKIM_CALL DKIMSignGetSig( DKIMContext* pSignContext, char* szPrivKey, char* szSignature, int nSigLength )
{
	CDKIMSign* pSign = (CDKIMSign*)ValidateContext( pSignContext, true );

	if( pSign )
	{
		return pSign->GetSig( szPrivKey, szSignature, nSigLength );
	}
	return DKIM_INVALID_CONTEXT;
}
*/
int DKIM_CALL DKIMSignGetSig2( DKIMContext* pSignContext, char* szPrivKey, char** pszSignature )
{
  CDKIMSign* pSign = (CDKIMSign*)ValidateContext( pSignContext, true );

  if( pSign ) { return pSign->GetSig2( szPrivKey, pszSignature ); }
  return DKIM_INVALID_CONTEXT;
}



void DKIM_CALL DKIMSignFree( DKIMContext* pSignContext )
{
	CDKIMSign* pSign = (CDKIMSign*)ValidateContext( pSignContext, true );

	if( pSign )
	{
		delete pSign;
		pSignContext->reserved3 = NULL;
	}
}


int DKIM_CALL DKIMVerifyInit( DKIMContext* pVerifyContext, DKIMVerifyOptions* pOptions )
{
	int nRet = DKIM_OUT_OF_MEMORY;

	CDKIMVerify* pVerify = new CDKIMVerify;

	if( pVerify )
	{
		nRet = pVerify->Init( pOptions );
		if( nRet != DKIM_SUCCESS )
			delete pVerify;
	}

	if( nRet == DKIM_SUCCESS )
	{
		InitContext( pVerifyContext, false, pVerify );
	}

	return nRet;
}


int DKIM_CALL DKIMVerifyProcess( DKIMContext* pVerifyContext, const char* const szBuffer, int nBufLength )
{
	CDKIMVerify* pVerify = (CDKIMVerify*)ValidateContext( pVerifyContext, false );

	if( pVerify )
	{
		return pVerify->Process( szBuffer, nBufLength, false );
	}
	
	return DKIM_INVALID_CONTEXT;
}

int DKIM_CALL DKIMVerifyResults( DKIMContext* pVerifyContext )
{
  CDKIMVerify* pVerify = (CDKIMVerify*)ValidateContext( pVerifyContext, false );

  if( pVerify ) { return pVerify->GetResults(); }
  return DKIM_INVALID_CONTEXT;
}

int DKIM_CALL DKIMVerifyGetDetails( DKIMContext* pVerifyContext, int* nSigCount, DKIMVerifyDetails** pDetails, char* szPractices )
{
	szPractices[0] = '\0';

	CDKIMVerify* pVerify = (CDKIMVerify*)ValidateContext( pVerifyContext, false );

	if( pVerify )
	{
		strcpy(szPractices, pVerify->GetPractices());
		return pVerify->GetDetails(nSigCount, pDetails);
	}

	return DKIM_INVALID_CONTEXT;
}


void DKIM_CALL DKIMVerifyFree( DKIMContext* pVerifyContext )
{
	CDKIMVerify* pVerify = (CDKIMVerify*)ValidateContext( pVerifyContext, false );

	if( pVerify )
	{
		delete pVerify;
		pVerifyContext->reserved3 = NULL;
	}
}

const char* DKIM_CALL DKIMVersion()
{
	return VERSION_STRING;
}

static const char* DKIMErrorStrings[-1-DKIM_MAX_ERROR] = {
  "DKIM_FAIL",
  "DKIM_BAD_SYNTAX",
  "DKIM_SIGNATURE_BAD",
  "DKIM_SIGNATURE_BAD_BUT_TESTING",
  "DKIM_SIGNATURE_EXPIRED",
  "DKIM_SELECTOR_INVALID",
  "DKIM_SELECTOR_GRANULARITY_MISMATCH",
  "DKIM_SELECTOR_KEY_REVOKED",
  "DKIM_SELECTOR_DOMAIN_NAME_TOO_LONG",
  "DKIM_SELECTOR_DNS_TEMP_FAILURE",
  "DKIM_SELECTOR_DNS_PERM_FAILURE",
  "DKIM_SELECTOR_PUBLIC_KEY_INVALID",
  "DKIM_NO_SIGNATURES",
  "DKIM_NO_VALID_SIGNATURES",
  "DKIM_BODY_HASH_MISMATCH",
  "DKIM_SELECTOR_ALGORITHM_MISMATCH",
  "DKIM_STAT_INCOMPAT",
  "DKIM_UNSIGNED_FROM",
  "DKIM_OUT_OF_MEMORY",
  "DKIM_INVALID_CONTEXT",
  "DKIM_NO_SENDER",
  "DKIM_BAD_PRIVATE_KEY",
  "DKIM_BUFFER_TOO_SMALL",
};

const char* DKIM_CALL DKIMGetErrorString( int ErrorCode ) {
  if (ErrorCode >= 0 || ErrorCode <= DKIM_MAX_ERROR)
    return "Unknown";
  else
    return DKIMErrorStrings[-1-ErrorCode];
}
