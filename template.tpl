___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Supabase Lookup",
  "description": "Supabase Lookup variable for GTM: Fetch, track, and analyze Supabase data in GTM effortlessly.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "projectUrl",
    "displayName": "Project Url",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "apiKey",
    "displayName": "API Key",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "tableName",
    "displayName": "Table Name",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "documentPath",
    "displayName": "Document Path",
    "simpleValueType": true,
    "help": "Allows for extracting values from response body. For example, using \u003cb\u003e0.email\u003c/b\u003e will return the email field from the first object in the response."
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "queryConditions",
    "displayName": "Query Conditions",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Key",
        "name": "key",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Value",
        "name": "value",
        "type": "TEXT"
      }
    ],
    "help": "\u003ca href\u003d\"https://postgrest.org/en/stable/references/api/tables_views.html#horizontal-filtering\"\u003eRead more\u003c/a\u003e"
  }
]


___SANDBOXED_JS_FOR_SERVER___

const sendHttpRequest = require('sendHttpRequest');
const encodeUri = require('encodeUri');
const JSON = require('JSON');

const url = getUrl();
const options = getOptions();

return sendHttpRequest(url, options).then(getResult);

function getUrl() {
  const url = data.projectUrl + '/rest/v1/' + encodeUri(data.tableName);
  const params = (data.queryConditions || []).map((item) => item.key + '=' + item.value).join('&');
  return params ? url + '?' + params : url;
}

function getOptions() {
  const headers = {
    'Content-Type': 'application/json',
    apikey: data.apiKey,
    Authorization: 'Bearer ' + data.apiKey,
  };
  return { headers: headers, method: 'GET' };
}

function getResult(response) {
  const body = JSON.parse(response.body);
  if (!data.documentPath) return body;
  const keys = data.documentPath.trim().split('.');
  let value = body;
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (!value || !key) break;
    value = value[key];
  }
  return value;
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 19/10/2023, 13:07:24


