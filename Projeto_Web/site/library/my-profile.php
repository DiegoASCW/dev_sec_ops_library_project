<?php 
session_start();
include('includes/config.php');

// Redirect if not logged in
if(empty($_SESSION['login'])) {   
    header('location:index.php');
    exit();
}

$message = '';
$messageType = '';

if(isset($_POST['update'])) {    
    $sid = $_SESSION['stdid'];  
    // Fixed typo: fullanme -> fullname
    $fname = trim($_POST['fullname']);
    $mobileno = trim($_POST['mobileno']);
    
    // Input validation
    if(empty($fname)) {
        $message = 'Full name is required';
        $messageType = 'error';
    } elseif(strlen($fname) > 120) {
        $message = 'Full name is too long';
        $messageType = 'error';
    } elseif(!preg_match('/^[0-9]{10}$/', $mobileno)) {
        $message = 'Mobile number must be exactly 10 digits';
        $messageType = 'error';
    } else {
        try {
            // Added UpdationDate to track when profile was last updated
            $sql = "UPDATE tblstudents SET FullName=:fname, MobileNumber=:mobileno, UpdationDate=NOW() WHERE StudentId=:sid";
            $query = $dbh->prepare($sql);
            $query->bindParam(':sid', $sid, PDO::PARAM_STR);
            $query->bindParam(':fname', $fname, PDO::PARAM_STR);
            $query->bindParam(':mobileno', $mobileno, PDO::PARAM_STR);
            
            if($query->execute() && $query->rowCount() > 0) {
                $message = 'Your profile has been updated successfully';
                $messageType = 'success';
            } else {
                $message = 'No changes were made or error updating profile';
                $messageType = 'error';
            }
        } catch(PDOException $e) {
            $message = 'Database error occurred. Please try again.';
            $messageType = 'error';
            // Log error for debugging: error_log($e->getMessage());
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="Student Profile Management" />
    <meta name="author" content="" />
    <title>Openshelf | My Profile</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href="https://fonts.googleapis.com/css?family=Open+Sans" rel="stylesheet" type="text/css" /> 
</head>
<body>
    <!------MENU SECTION START-->
    <?php include('includes/header.php');?>
    <!-- MENU SECTION END-->
    
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">My Profile</h4>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-9 col-md-offset-1">
                    <div class="panel panel-danger">
                        <div class="panel-heading">
                            My Profile
                        </div>
                        <div class="panel-body">
                            <?php if(!empty($message)): ?>
                                <div class="alert alert-<?php echo $messageType === 'success' ? 'success' : 'danger'; ?> alert-dismissible">
                                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                                    <?php echo htmlspecialchars($message); ?>
                                </div>
                            <?php endif; ?>
                            
                            <?php 
                            $sid = $_SESSION['stdid'];
                            $sql = "SELECT StudentId, FullName, EmailId, MobileNumber, RegDate, UpdationDate, Status FROM tblstudents WHERE StudentId=:sid";
                            $query = $dbh->prepare($sql);
                            $query->bindParam(':sid', $sid, PDO::PARAM_STR);
                            $query->execute();
                            $results = $query->fetchAll(PDO::FETCH_OBJ);
                            
                            if($query->rowCount() > 0) {
                                foreach($results as $result) {               
                            ?>  
                            
                            <form name="profile" method="post" novalidate>
                                <div class="form-group">
                                    <label>Student ID:</label>
                                    <div class="form-control-static"><strong><?php echo htmlspecialchars($result->StudentId); ?></strong></div>
                                </div>

                                <div class="form-group">
                                    <label>Registration Date:</label>
                                    <div class="form-control-static"><?php echo htmlspecialchars($result->RegDate); ?></div>
                                </div>
                                
                                <?php if(!empty($result->UpdationDate)): ?>
                                <div class="form-group">
                                    <label>Last Update Date:</label>
                                    <div class="form-control-static"><?php echo htmlspecialchars($result->UpdationDate); ?></div>
                                </div>
                                <?php endif; ?>

                                <div class="form-group">
                                    <label>Profile Status:</label>
                                    <div class="form-control-static">
                                        <?php if($result->Status == 1): ?>
                                            <span class="label label-success">Active</span>
                                        <?php else: ?>
                                            <span class="label label-danger">Blocked</span>
                                        <?php endif; ?>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label for="fullname">Full Name <span class="text-danger">*</span></label>
                                    <input class="form-control" 
                                           type="text" 
                                           name="fullname" 
                                           id="fullname"
                                           value="<?php echo htmlspecialchars($result->FullName); ?>" 
                                           maxlength="120"
                                           autocomplete="name" 
                                           required />
                                </div>

                                <div class="form-group">
                                    <label for="mobileno">Mobile Number <span class="text-danger">*</span></label>
                                    <input class="form-control" 
                                           type="tel" 
                                           name="mobileno" 
                                           id="mobileno"
                                           maxlength="10" 
                                           pattern="[0-9]{10}"
                                           value="<?php echo htmlspecialchars($result->MobileNumber); ?>" 
                                           autocomplete="tel" 
                                           required />
                                    <small class="help-block">Enter 10-digit mobile number</small>
                                </div>
                                        
                                <div class="form-group">
                                    <label for="email">Email Address</label>
                                    <input class="form-control" 
                                           type="email" 
                                           name="email" 
                                           id="email" 
                                           value="<?php echo htmlspecialchars($result->EmailId); ?>"  
                                           autocomplete="email" 
                                           readonly />
                                    <small class="help-block">Email cannot be changed</small>
                                </div>
                                
                                <button type="submit" name="update" class="btn btn-primary">
                                    <i class="fa fa-save"></i> Update Profile
                                </button>
                                
                                <a href="dashboard.php" class="btn btn-default">
                                    <i class="fa fa-arrow-left"></i> Back to Dashboard
                                </a>
                            </form>
                            
                            <?php 
                                }
                            } else {
                                echo '<div class="alert alert-danger">Profile not found. Please <a href="logout.php">logout</a> and login again.</div>';
                            }
                            ?>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- CONTENT-WRAPPER SECTION END-->
    <?php include('includes/footer.php');?>
    
    <script src="assets/js/jquery-1.10.2.js"></script>
    <!-- BOOTSTRAP SCRIPTS  -->
    <script src="assets/js/bootstrap.js"></script>
    <!-- CUSTOM SCRIPTS  -->
    <script src="assets/js/custom.js"></script>
    
    <script>
    // Client-side validation
    document.querySelector('form[name="profile"]').addEventListener('submit', function(e) {
        const fname = document.getElementById('fullname').value.trim();
        const mobile = document.getElementById('mobileno').value.trim();
        
        if(fname.length === 0) {
            alert('Full name is required');
            document.getElementById('fullname').focus();
            e.preventDefault();
            return false;
        }
        
        if(!/^[0-9]{10}$/.test(mobile)) {
            alert('Mobile number must be exactly 10 digits');
            document.getElementById('mobileno').focus();
            e.preventDefault();
            return false;
        }
        
        return true;
    });
    </script>
</body>
</html>