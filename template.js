const sendHttpRequest = require('sendHttpRequest');
const encodeUri = require('encodeUri');
const JSON = require('JSON');
const templateDataStorage = require('templateDataStorage');
const Promise = require('Promise');
const sha256Sync = require('sha256Sync');

return getResponseBody().then(mapResponse);

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

function mapResponse(bodyString) {
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

function getResponseBody() {
  const url = getUrl();
  const options = getOptions();
  const cacheKey = data.storeResponse ? sha256Sync(url + JSON.stringify(options)) : '';
  if (data.storeResponse) {
    const cachedValue = templateDataStorage.getItemCopy(cacheKey);
    if (cachedValue) return Promise.create((resolve) => resolve(cachedValue));
  }
  return sendHttpRequest(url, options).then((response) => {
    if (data.storeResponse) templateDataStorage.setItemCopy(cacheKey, response.body);
    return response.body;
  });
}
