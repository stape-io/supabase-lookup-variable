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
    "type": "CHECKBOX",
    "name": "storeResponse",
    "checkboxText": "Store the result in cache",
    "simpleValueType": true,
    "help": "Store the result in Template Storage. If all parameters of the query are the same resul will be taken from the cache if it exists."
  },
  {
    "type": "GROUP",
    "name": "queryGroup",
    "displayName": "Query conditions",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "SIMPLE_TABLE",
        "name": "queryConditions",
        "simpleTableColumns": [
          {
            "defaultValue": "",
            "displayName": "Key",
            "name": "key",
            "type": "TEXT",
            "isUnique": true
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
  },
  {
    "displayName": "Logs Settings",
    "name": "logsGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "RADIO",
        "name": "logType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log"
          },
          {
            "value": "debug",
            "displayValue": "Log to console during debug and preview"
          },
          {
            "value": "always",
            "displayValue": "Always log to console"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "debug"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const createRegex = require('createRegex');
const encodeUriComponent = require('encodeUriComponent');
const getAllEventData = require('getAllEventData');
const getContainerVersion = require('getContainerVersion');
const getRequestHeader = require('getRequestHeader');
const getType = require('getType');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const makeString = require('makeString');
const Promise = require('Promise');
const sendHttpRequest = require('sendHttpRequest');
const sha256Sync = require('sha256Sync');
const templateDataStorage = require('templateDataStorage');

/*==============================================================================
==============================================================================*/

const eventData = getAllEventData();

if (shouldExitEarly(eventData)) return;

return lookupSupabase().then(mapResponse);

/*==============================================================================
Vendor related functions
==============================================================================*/

function getUrl() {
  if (!data.projectUrl) return undefined;
  const baseUrl = data.projectUrl.replace(createRegex('/$'), '');
  const url = baseUrl + '/rest/v1/' + enc(data.tableName);
  const params = (data.queryConditions || []).map((item) => enc(item.key) + '=' + enc(item.value)).join('&');
  return params ? url + '?' + params : url;
}

function getOptions() {
  const headers = {
    'Content-Type': 'application/json',
    apikey: data.apiKey,
    Authorization: 'Bearer ' + data.apiKey
  };
  return { headers: headers, method: 'GET' };
}

function lookupSupabase() {
  const url = getUrl();
  if (!url) return Promise.create((resolve) => resolve('{}'));

  const options = getOptions();
  const cacheKey = data.storeResponse ? sha256Sync(url + JSON.stringify(options)) : '';
  if (data.storeResponse) {
    const cachedValue = templateDataStorage.getItemCopy(cacheKey);
    if (!!cachedValue) return Promise.create((resolve) => resolve(cachedValue));
  }

  log({
    Name: 'SupabaseLookup',
    Type: 'Request',
    EventName: 'StoreRead',
    RequestMethod: options.method,
    RequestUrl: url,
    RequestBody: options
  });

  return sendHttpRequest(url, options)
    .then((response) => {
      log({
        Name: 'SupabaseLookup',
        Type: 'Response',
        EventName: 'StoreRead',
        ResponseStatusCode: response.statusCode,
        ResponseHeaders: response.headers,
        ResponseBody: response.body
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.storeResponse) templateDataStorage.setItemCopy(cacheKey, response.body);
        return response.body;
      }
      return undefined;
    })
    .catch((error) => {
      log({
        Name: 'SupabaseLookup',
        Type: 'Message',
        EventName: 'StoreRead',
        Message: 'The request failed or timed out.',
        Reason: JSON.stringify(error)
      });
      return undefined;
    });
}

function mapResponse(bodyString) {
  if (!bodyString) return undefined;
  const body = JSON.parse(bodyString);
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

/*==============================================================================
Helpers
==============================================================================*/

function shouldExitEarly(eventData) {
  const url = eventData.page_location || getRequestHeader('referer');
  if (url && url.lastIndexOf('https://gtm-msr.appspot.com/', 0) === 0) return true;
  return false;
}

function enc(data) {
  if (['null', 'undefined'].indexOf(getType(data)) !== -1) data = '';
  return encodeUriComponent(makeString(data));
}

function log(rawDataToLog) {
  const logDestinationsHandlers = {};
  if (determinateIsLoggingEnabled()) logDestinationsHandlers.console = logConsole;

  rawDataToLog.TraceId = getRequestHeader('trace-id');

  for (const logDestination in logDestinationsHandlers) {
    const handler = logDestinationsHandlers[logDestination];
    if (!handler) continue;

    const dataToLog = rawDataToLog;

    handler(dataToLog);
  }
}

function logConsole(dataToLog) {
  logToConsole(JSON.stringify(dataToLog));
}

function determinateIsLoggingEnabled() {
  const containerVersion = getContainerVersion();
  const isDebug = !!(containerVersion && (containerVersion.debugMode || containerVersion.previewMode));

  if (!data.logType) {
    return isDebug;
  }

  if (data.logType === 'no') {
    return false;
  }

  if (data.logType === 'debug') {
    return isDebug;
  }

  return data.logType === 'always';
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
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "headerWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trace-id"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "referer"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterAccess",
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
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
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

scenarios:
- name: '[URL Construction] Strips trailing slash and appends query params'
  code: |-
    const mockData = {
      projectUrl: 'https://my-project.supabase.co/', // Trailing slash included
      apiKey: 'mock-api-key',
      tableName: 'orders',
      queryConditions: [
        { key: 'status', value: 'eq.completed' },
        { key: 'total', value: 'gt.100' }
      ]
    };

    let requestedUrl = '';
    mock('sendHttpRequest', (url, options) => {
      requestedUrl = url;
      return Promise.create((resolve) => resolve({ statusCode: 200, body: '[]' }));
    });

    runCode(mockData).then(() => {
      assertThat(requestedUrl).isEqualTo('https://my-project.supabase.co/rest/v1/orders?status=eq.completed&total=gt.100');
    });
- name: '[Success] Successfully parses JSON and extracts document path'
  code: |-
    const mockData = {
      projectUrl: 'https://my-project.supabase.co',
      apiKey: 'mock-api-key',
      tableName: 'users',
      documentPath: '0.name', // Extract 'name' from the first object
      storeResponse: false
    };

    mock('sendHttpRequest', (url, options) => {
      return Promise.create((resolve) => resolve({
        statusCode: 200,
        body: JSON.stringify([{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }])
      }));
    });

    runCode(mockData).then((result) => {
      assertThat(result).isEqualTo('Alice');
    });
- name: '[Failure] Silently returns undefined if API returns invalid JSON'
  code: |-
    const mockData = {
      projectUrl: 'https://my-project.supabase.co',
      apiKey: 'mock-api-key',
      tableName: 'users',
      documentPath: '0.name'
    };

    mock('sendHttpRequest', () => {
      return Promise.create((resolve) => resolve({
        statusCode: 502,
        body: '<html>Bad Gateway</html>' // Not valid JSON
      }));
    });

    runCode(mockData).then((result) => {
      assertThat(result).isUndefined();
    });
- name: '[Guard Clause] Exits early if referer is GTM domain'
  code: |
    const mockData = {
      projectUrl: 'https://my-project.supabase.co',
      apiKey: 'mock-api-key',
      tableName: 'users'
    };

    mock('getRequestHeader', (header) => {
      if (header === 'referer') return 'https://gtm-msr.appspot.com/render';
      return undefined;
    });

    const result = runCode(mockData);

    assertApi('sendHttpRequest').wasNotCalled();
    assertThat(result).isUndefined();
setup: |-
  const JSON = require('JSON');
  const Promise = require('Promise');

  mock('getAllEventData', () => ({}));

  mock('getRequestHeader', (header) => {
    if (header === 'trace-id') return 'trace-123';
    return undefined;
  });

  mock('getContainerVersion', () => ({ debugMode: true }));
  mock('logToConsole', () => {});
  mock('getTimestampMillis', () => 1000000);

  mockObject('templateDataStorage', {
    getItemCopy: () => null,
    setItemCopy: () => {}
  });

  mock('sendHttpRequest', () => {
    return Promise.create((resolve) => resolve({ statusCode: 200, body: '{}' }));
  });


___NOTES___

Created on 19/10/2023, 14:06:55

2026-04-27 Change Notes:
 - Bump the template to Stape Standards
 - Major code refactor, fix pitfalls, add failsafes
 - Add tests.
