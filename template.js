const encodeUriComponent = require('encodeUriComponent');
const getAllEventData = require('getAllEventData');
const getRequestHeader = require('getRequestHeader');
const getType = require('getType');
const JSON = require('JSON');
const makeString = require('makeString');
const Promise = require('Promise');
const sendHttpRequest = require('sendHttpRequest');
const sha256Sync = require('sha256Sync');
const templateDataStorage = require('templateDataStorage');

/*==============================================================================
==============================================================================*/

const eventData = getAllEventData();
const API_VERSION = '1';

if (shouldExitEarly(eventData)) return;

return lookupSupabase().then(mapResponse);

/*==============================================================================
Vendor related functions
==============================================================================*/

function getUrl() {
  if (!data.projectUrl || !data.tableName) return undefined;
  const baseUrl = data.projectUrl.charAt(data.projectUrl.length - 1) === '/' ? data.projectUrl.slice(0, -1) : data.projectUrl;
  const url = baseUrl + '/rest/v' + API_VERSION + '/' + enc(data.tableName);
  const params = (data.queryConditions || []).map((item) => enc(item.key) + '=' + enc(item.value)).join('&');
  return url + (params ? '?' + params : '');
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
  if (!url) return Promise.create((resolve) => resolve(undefined));

  const options = getOptions();
  const cacheKey = data.storeResponse ? sha256Sync(url + JSON.stringify(options)) : '';
  if (data.storeResponse) {
    const cachedValue = templateDataStorage.getItemCopy(cacheKey);
    if (cachedValue) return Promise.create((resolve) => resolve(cachedValue));
  }

  return sendHttpRequest(url, options)
    .then((response) => {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.storeResponse) templateDataStorage.setItemCopy(cacheKey, response.body);
        return response.body;
      }
      return undefined;
    })
    .catch((error) => {
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
