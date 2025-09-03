<?php
session_start();
include('includes/config.php');
include('includes/cognito-config.php');

if (isset($_SESSION['alogin'])) {
    unset($_SESSION['alogin']);
}

if (isset($_POST['login'])) {
    $username = $_POST['username'];
    $password = $_POST['password'];

    try {
        $authResult = $cognitoClient->initiateAuth([
            'AuthFlow'       => 'USER_PASSWORD_AUTH',
            'ClientId'       => AWS_COGNITO_CLIENT_ID,
            'AuthParameters' => [
                'USERNAME'    => $username,
                'PASSWORD'    => $password,
                'SECRET_HASH' => generateSecretHash($username), // <-- Posição correta
            ],
        ]);

        $groupsResult = $cognitoClient->adminListGroupsForUser([
            'UserPoolId' => AWS_COGNITO_USER_POOL_ID,
            'Username'   => $username,
        ]);

        $isAdmin = false;
        foreach ($groupsResult['Groups'] as $group) {
            if ($group['GroupName'] === 'Admins') {
                $isAdmin = true;
                break;
            }
        }

        if ($isAdmin) {
            $_SESSION['alogin'] = $username;
            echo "<script type='text/javascript'> document.location ='admin/dashboard.php'; </script>";
            exit();
        } else {
            echo "<script>alert('Access Denied: You are not an authorized administrator.');</script>";
        }

    } catch (Aws\CognitoIdentityProvider\Exception\CognitoIdentityProviderException $e) {
        echo "<script>alert('Invalid Details: " . addslashes($e->getAwsErrorMessage()) . "');</script>";
    } catch (Exception $e) {
        echo "<script>alert('An unexpected error occurred.');</script>";
    }
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Openshelf | Admin Login</title>
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <link href="assets/css/style.css" rel="stylesheet" />
    <link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
</head>
<body>
    <?php include('includes/header.php'); ?>
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12"><h4 class="header-line">ADMIN LOGIN FORM</h4></div>
            </div>
            <div class="row">
                <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                    <div class="panel panel-info">
                        <div class="panel-heading">LOGIN FORM</div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <div class="form-group">
                                    <label>Enter Username (Email)</label>
                                    <input class="form-control" type="text" name="username" autocomplete="off" required />
                                </div>
                                <div class="form-group">
                                    <label>Password</label>
                                    <input class="form-control" type="password" name="password" autocomplete="off" required />
                                </div>
                                <button type="submit" name="login" class="btn btn-info">LOGIN</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <?php include('includes/footer.php'); ?>
    <script src="assets/js/jquery-1.10.2.js"></script>
    <script src="assets/js/bootstrap.js"></script>
    <script src="assets/js/jquery.dataTables.js"></script>
    <script src="assets/js/custom.js"></script>
</body>
</html>