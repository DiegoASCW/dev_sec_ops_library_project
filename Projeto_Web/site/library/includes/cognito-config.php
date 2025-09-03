<?php
// library/includes/cognito-config.php

require_once __DIR__ . '/../vendor/autoload.php';

use Aws\CognitoIdentityProvider\CognitoIdentityProviderClient;
use Aws\Exception\AwsException;

// --- AWS AND COGNITO CONFIGURATION ---

define('AWS_REGION', getenv('AWS_REGION') ?: 'us-east-1');
define('AWS_COGNITO_USER_POOL_ID', getenv('COGNITO_USER_POOL_ID'));
define('AWS_COGNITO_CLIENT_ID', getenv('COGNITO_APP_CLIENT_ID'));
define('AWS_COGNITO_CLIENT_SECRET', getenv('COGNITO_APP_CLIENT_SECRET'));

// --- INITIALIZE AWS COGNITO CLIENT ---
try {
    $cognitoClient = new CognitoIdentityProviderClient([
        'version' => 'latest',
        'region'  => AWS_REGION,
        // If you inject IAM creds into the container, uncomment:
        // 'credentials' => [
        //     'key'    => getenv('AWS_ACCESS_KEY_ID'),
        //     'secret' => getenv('AWS_SECRET_ACCESS_KEY'),
        // ],
    ]);
} catch (Exception $e) {
    error_log("Error creating AWS client: " . $e->getMessage());
    die("A critical error occurred. Please check the server logs for more information.");
}


function generateSecretHash($username) {
    $hmac = hash_hmac(
        'sha256',
        $username . AWS_COGNITO_CLIENT_ID,
        AWS_COGNITO_CLIENT_SECRET,
        true
    );
    return base64_encode($hmac);
}