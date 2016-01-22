'use strict';
var myShopifyApp = {};

myShopifyApp.getUrlParam = function (name) {
  return (location.search.split(name + '=')[1]||'').split('&')[0];
};

myShopifyApp.appOnReady = function () {
  var identityPoolId = myShopifyApp.getUrlParam('pool_id');
  var identityId = myShopifyApp.getUrlParam('identity_id');
  var identityToken = myShopifyApp.getUrlParam('token');

  AWS.config.region = 'us-east-1';

  AWS.config.credentials = new AWS.CognitoIdentityCredentials({
    IdentityPoolId: identityPoolId,
    IdentityId: identityId,
    Logins: {
      'cognito-identity.amazonaws.com': identityToken
    }
  });

  AWS.config.credentials.refresh(function (err) {
    if (err) {
      console.log(err);
    } else {
      console.log(AWS.config.credentials.expireTime);
    }
  })
};
