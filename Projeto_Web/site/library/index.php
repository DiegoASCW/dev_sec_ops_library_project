<?php
// Always start the session at the very top.
session_start();

include('includes/config.php');
include('includes/cognito-config.php');

// If a user is already logged in, redirect to the dashboard.
if (isset($_SESSION['login']) && !empty($_SESSION['login'])) {
    header("Location: dashboard.php");
    exit();
}

// --- LOGIN LOGIC ---
if (isset($_POST['login'])) {
    $email = $_POST['emailid'];
    $password = $_POST['password'];

    try {
      $result = $cognitoClient->initiateAuth([
          'AuthFlow'       => 'USER_PASSWORD_AUTH',
          'ClientId'       => AWS_COGNITO_CLIENT_ID,
          'AuthParameters' => [
              'USERNAME'   => $email,
              'PASSWORD'   => $password,
              'SECRET_HASH'=> generateSecretHash($email),
          ],
      ]);


        // If successful, store session data.
        $idToken = $result->get('AuthenticationResult')['IdToken'];
        $_SESSION['login'] = $email;
        $_SESSION['id_token'] = $idToken;

        list($header, $payload, $signature) = explode('.', $idToken);
        $payloadData = json_decode(base64_decode($payload), true);
        $_SESSION['stdid'] = $payloadData['sub'];

        // Redirect to the dashboard.
        echo "<script type='text/javascript'> document.location ='dashboard.php'; </script>";

    } catch (Aws\CognitoIdentityProvider\Exception\CognitoIdentityProviderException $e) {
        echo "<script>alert('Invalid Details: " . addslashes($e->getAwsErrorMessage()) . "');</script>";
    } catch (Exception $e) {
         echo "<script>alert('DEBUG: " . addslashes($e->getMessage()) . "');</script>";
    }
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w.org/1999/xhtml">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
  <title>Openshelf</title>
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
        <div class="col-md-12">
          <h4 class="header-line">USER LOGIN FORM</h4>
        </div>
      </div>
      <div class="row">
        <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
          <div class="panel panel-info">
            <div class="panel-heading">LOGIN FORM</div>
            <div class="panel-body">
              <form role="form" method="post">
                <div class="form-group">
                  <label>Enter Email id</label>
                  <input class="form-control" type="text" name="emailid" required autocomplete="off" />
                </div>
                <div class="form-group">
                  <label>Password</label>
                  <input class="form-control" type="password" name="password" required autocomplete="off" />
                  <p class="help-block"><a href="user-forgot-password.php">Forgot Password</a></p>
                </div>
                <button type="submit" name="login" class="btn btn-info">LOGIN </button> | <a href="signup.php">Not Register Yet</a> | <a href="confirm.php">Confirmar sua conta?</a>
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