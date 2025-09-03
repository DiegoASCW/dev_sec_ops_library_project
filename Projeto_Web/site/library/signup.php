<?php
session_start();
include('includes/config.php');
include('includes/cognito-config.php');

if (isset($_POST['signup'])) {
    $email = $_POST['email'];
    $password = $_POST['password'];
    $fullName = $_POST['fullanme'];
    $mobileNumber = $_POST['mobileno'];
    $formattedMobile = '+55' . preg_replace('/\D/', '', $mobileNumber);

    try {
        $result = $cognitoClient->signUp([
            'ClientId'   => AWS_COGNITO_CLIENT_ID,
            // THIS LINE WAS ADDED TO FIX THE ERROR
            'SecretHash' => generateSecretHash($email),
            'Username'   => $email,
            'Password'   => $password,
            'UserAttributes' => [
                ['Name' => 'name', 'Value' => $fullName],
                ['Name' => 'phone_number', 'Value' => $formattedMobile],
                ['Name' => 'email', 'Value' => $email]
            ],
        ]);

        echo '<script>alert("Registration successful! Please check your email to confirm your account."); document.location="index.php";</script>';
        exit();

    } catch (Aws\CognitoIdentityProvider\Exception\CognitoIdentityProviderException $e) {
        echo "<script>alert('Error during registration: " . addslashes($e->getAwsErrorMessage()) . "');</script>";
    } catch (Exception $e) {
        echo "<script>alert('An unexpected error occurred. Please try again.');</script>";
    }
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Openshelf | Student Signup</title>
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <link href="assets/css/style.css" rel="stylesheet" />
    <link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    <script type="text/javascript">
        function valid() {
            if (document.signup.password.value != document.signup.confirmpassword.value) {
                alert("Password and Confirm Password Field do not match!");
                document.signup.confirmpassword.focus();
                return false;
            }
            return true;
        }
    </script>
</head>
<body>
    <?php include('includes/header.php'); ?>
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12"><h4 class="header-line">User Signup</h4></div>
            </div>
            <div class="row">
                <div class="col-md-9 col-md-offset-1">
                    <div class="panel panel-danger">
                        <div class="panel-heading">SIGNUP FORM</div>
                        <div class="panel-body">
                            <form name="signup" method="post" onSubmit="return valid();">
                                <div class="form-group">
                                    <label>Enter Full Name</label>
                                    <input class="form-control" type="text" name="fullanme" autocomplete="off" required />
                                </div>
                                <div class="form-group">
                                    <label>Mobile Number :</label>
                                    <input class="form-control" type="text" name="mobileno" maxlength="11" autocomplete="off" required />
                                </div>
                                <div class="form-group">
                                    <label>Enter Email</label>
                                    <input class="form-control" type="email" name="email" id="emailid" autocomplete="off" required />
                                </div>
                                <div class="form-group">
                                    <label>Enter Password</label>
                                    <input class="form-control" type="password" name="password" autocomplete="off" required />
                                </div>
                                <div class="form-group">
                                    <label>Confirm Password</label>
                                    <input class="form-control" type="password" name="confirmpassword" autocomplete="off" required />
                                </div>
                                <button type="submit" name="signup" class="btn btn-danger" id="submit">Register Now</button>
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