<?php
session_start();
include('includes/config.php');
error_reporting(0);

if (isset($_POST['signup'])) {
    try {
        // Code for captcha verification
        if ($_POST["vercode"] != $_SESSION["vercode"] or $_SESSION["vercode"] == '') {
            echo "<script>alert('Incorrect verification code');</script>";
        } else {
            $email = $_POST['email'];
            
            // Check if email already exists
            $emailCheck = "SELECT EmailId FROM tblstudents WHERE EmailId=:email";
            $emailQuery = $dbh->prepare($emailCheck);
            $emailQuery->bindParam(':email', $email, PDO::PARAM_STR);
            $emailQuery->execute();
            
            if ($emailQuery->rowCount() > 0) {
                echo "<script>alert('Email already exists. Please use different email.');</script>";
            } else {
                // Code for student ID
                $count_my_page = "studentid.txt";
                
                // Check if file exists, create if not
                if (!file_exists($count_my_page)) {
                    file_put_contents($count_my_page, "1000");
                }
                
                $hits = file($count_my_page);
                $hits[0]++;
                $fp = fopen($count_my_page, "w");
                if ($fp) {
                    fputs($fp, "$hits[0]");
                    fclose($fp);
                    $StudentId = $hits[0];
                } else {
                    throw new Exception("Could not generate student ID");
                }
                
                $fname = $_POST['fullname'];
                $mobileno = $_POST['mobileno'];
                // Fixed: Use same hashing method as login
                $password = hash('sha256', $_POST['password']);
                $status = 1;
                
                $sql = "INSERT INTO tblstudents(StudentId,FullName,MobileNumber,EmailId,Password,Status) VALUES(:StudentId,:fname,:mobileno,:email,:password,:status)";
                $query = $dbh->prepare($sql);
                $query->bindParam(':StudentId', $StudentId, PDO::PARAM_STR);
                $query->bindParam(':fname', $fname, PDO::PARAM_STR);
                $query->bindParam(':mobileno', $mobileno, PDO::PARAM_STR);
                $query->bindParam(':email', $email, PDO::PARAM_STR);
                $query->bindParam(':password', $password, PDO::PARAM_STR);
                $query->bindParam(':status', $status, PDO::PARAM_STR);
                $query->execute();
                
                $lastInsertId = $dbh->lastInsertId();
                if ($lastInsertId) {
                    echo '<script>alert("Registration successful! Your student ID is: ' . $StudentId . '"); window.location.href="index.php";</script>';
                } else {
                    echo "<script>alert('Something went wrong. Please try again');</script>";
                }
            }
        }
    } catch (Exception $e) {
        echo "<script>alert('Error: " . addslashes($e->getMessage()) . "');</script>";
    }
}
?>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Openshelf | Student Signup</title>
    <!-- Your existing CSS links -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <link href="assets/css/style.css" rel="stylesheet" />
    <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    
    <script type="text/javascript">
        function valid() {
            if (document.signup.password.value.length < 6) {
                alert("Password must be at least 6 characters long!");
                document.signup.password.focus();
                return false;
            }
            if (document.signup.password.value != document.signup.confirmpassword.value) {
                alert("Password and Confirm Password do not match!");
                document.signup.confirmpassword.focus();
                return false;
            }
            return true;
        }
    </script>
    
    <script src="assets/js/jquery-1.10.2.js"></script>
    <script>
        function checkAvailability() {
            $("#loaderIcon").show();
            jQuery.ajax({
                url: "check_availability.php",
                data: 'emailid=' + $("#emailid").val(),
                type: "POST",
                success: function(data) {
                    $("#user-availability-status").html(data);
                    $("#loaderIcon").hide();
                },
                error: function() {
                    $("#user-availability-status").html("Error checking availability");
                    $("#loaderIcon").hide();
                }
            });
        }
    </script>
</head>

<body>
    <?php include('includes/header.php'); ?>
    
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">User Signup</h4>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-9 col-md-offset-1">
                    <div class="panel panel-danger">
                        <div class="panel-heading">SIGNUP FORM</div>
                        <div class="panel-body">
                            <form name="signup" method="post" onSubmit="return valid();">
                                <div class="form-group">
                                    <label>Enter Full Name</label>
                                    <input class="form-control" type="text" name="fullname" autocomplete="off" required />
                                </div>

                                <div class="form-group">
                                    <label>Mobile Number :</label>
                                    <input class="form-control" type="text" name="mobileno" maxlength="15" pattern="[0-9]{10,15}" title="Enter valid mobile number" autocomplete="off" required />
                                </div>

                                <div class="form-group">
                                    <label>Enter Email</label>
                                    <input class="form-control" type="email" name="email" id="emailid" onBlur="checkAvailability()" autocomplete="off" required />
                                    <span id="user-availability-status" style="font-size:12px;"></span>
                                </div>

                                <div class="form-group">
                                    <label>Enter Password</label>
                                    <input class="form-control" type="password" name="password" minlength="6" title="Password must be at least 6 characters long" autocomplete="off" required />
                                </div>

                                <div class="form-group">
                                    <label>Confirm Password</label>
                                    <input class="form-control" type="password" name="confirmpassword" autocomplete="off" required />
                                </div>
                                
                                <div class="form-group">
                                    <label>Verification code :</label>
                                    <input type="text" name="vercode" maxlength="5" autocomplete="off" required style="width: 150px; height: 25px;" />&nbsp;<img src="captcha.php">
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
    <script src="assets/js/bootstrap.js"></script>
    <script src="assets/js/custom.js"></script>
</body>
</html>