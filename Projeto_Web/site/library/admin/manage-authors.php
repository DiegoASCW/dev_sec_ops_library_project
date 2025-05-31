<?php
session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);
include('../includes/config.php');

// Check authentication
if(strlen($_SESSION['alogin'])==0) {   
    header('location:index.php');
    exit();
}

// Handle deletion with CSRF protection
if(isset($_GET['del']) && isset($_GET['token'])) {
    // Verify CSRF token
    if(!hash_equals($_SESSION['csrf_token'], $_GET['token'])) {
        $_SESSION['error'] = "Invalid security token";
        header('location:manage-authors.php');
        exit();
    }
    
    $id = filter_var($_GET['del'], FILTER_VALIDATE_INT);
    if($id === false || $id <= 0) {
        $_SESSION['error'] = "Invalid author ID";
        header('location:manage-authors.php');
        exit();
    }
    
    try {
        $sql = "DELETE FROM tblauthors WHERE id = :id";
        $query = $dbh->prepare($sql);
        $query->bindParam(':id', $id, PDO::PARAM_INT);
        $query->execute();
        
        if($query->rowCount() > 0) {
            $_SESSION['delmsg'] = "Author deleted successfully";
        } else {
            $_SESSION['error'] = "Author not found";
        }
    } catch(PDOException $e) {
        $_SESSION['error'] = "Database error occurred";
        error_log("Delete author error: " . $e->getMessage());
    }
    
    header('location:manage-authors.php');
    exit();
}

// Generate CSRF token
if(!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// Initialize session variables if not set
$session_vars = ['error', 'msg', 'updatemsg', 'delmsg'];
foreach($session_vars as $var) {
    if(!isset($_SESSION[$var])) {
        $_SESSION[$var] = "";
    }
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | Manage Authors</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- DATATABLE STYLE  -->
    <link href="assets/js/dataTables/dataTables.bootstrap.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
</head>
<body>
    <!------MENU SECTION START-->
    <?php include('includes/header.php');?>
    <!-- MENU SECTION END-->
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">Manage Authors</h4>
                </div>
            </div>
            
            <div class="row">
                <?php if($_SESSION['error'] != ""): ?>
                <div class="col-md-6">
                    <div class="alert alert-danger">
                        <strong>Error:</strong> 
                        <?php echo htmlentities($_SESSION['error']); ?>
                    </div>
                </div>
                <?php $_SESSION['error'] = ""; ?>
                <?php endif; ?>
                
                <?php if($_SESSION['msg'] != ""): ?>
                <div class="col-md-6">
                    <div class="alert alert-success">
                        <strong>Success:</strong> 
                        <?php echo htmlentities($_SESSION['msg']); ?>
                    </div>
                </div>
                <?php $_SESSION['msg'] = ""; ?>
                <?php endif; ?>
                
                <?php if($_SESSION['updatemsg'] != ""): ?>
                <div class="col-md-6">
                    <div class="alert alert-success">
                        <strong>Success:</strong> 
                        <?php echo htmlentities($_SESSION['updatemsg']); ?>
                    </div>
                </div>
                <?php $_SESSION['updatemsg'] = ""; ?>
                <?php endif; ?>

                <?php if($_SESSION['delmsg'] != ""): ?>
                <div class="col-md-6">
                    <div class="alert alert-success">
                        <strong>Success:</strong> 
                        <?php echo htmlentities($_SESSION['delmsg']); ?>
                    </div>
                </div>
                <?php $_SESSION['delmsg'] = ""; ?>
                <?php endif; ?>
            </div>

            <div class="row">
                <div class="col-md-12">
                    <!-- Advanced Tables -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                           Authors Listing
                        </div>
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered table-hover" id="dataTables-example">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Author</th>
                                            <th>Creation Date</th>
                                            <th>Updation Date</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php 
                                        try {
                                            $sql = "SELECT * FROM tblauthors ORDER BY AuthorName";
                                            $query = $dbh->prepare($sql);
                                            $query->execute();
                                            $results = $query->fetchAll(PDO::FETCH_OBJ);
                                            $cnt = 1;
                                            
                                            if($query->rowCount() > 0) {
                                                foreach($results as $result) { 
                                        ?>                                      
                                        <tr class="odd gradeX">
                                            <td class="center"><?php echo htmlentities($cnt); ?></td>
                                            <td class="center"><?php echo htmlentities($result->AuthorName); ?></td>
                                            <td class="center"><?php echo htmlentities($result->creationDate); ?></td>
                                            <td class="center"><?php echo htmlentities($result->UpdationDate); ?></td>
                                            <td class="center">
                                                <a href="edit-author.php?athrid=<?php echo htmlentities($result->id); ?>">
                                                    <button class="btn btn-primary">
                                                        <i class="fa fa-edit"></i> Edit
                                                    </button>
                                                </a>
                                                <a href="manage-authors.php?del=<?php echo htmlentities($result->id); ?>&token=<?php echo htmlentities($_SESSION['csrf_token']); ?>" 
                                                   onclick="return confirm('Are you sure you want to delete this author?');">
                                                    <button class="btn btn-danger">
                                                        <i class="fa fa-trash"></i> Delete
                                                    </button>
                                                </a>
                                            </td>
                                        </tr>
                                        <?php 
                                                    $cnt++; 
                                                }
                                            } else {
                                        ?>
                                        <tr>
                                            <td colspan="5" class="center">No authors found</td>
                                        </tr>
                                        <?php 
                                            }
                                        } catch(PDOException $e) {
                                            echo '<tr><td colspan="5" class="center text-danger">Error loading authors</td></tr>';
                                            error_log("Fetch authors error: " . $e->getMessage());
                                        }
                                        ?>                                      
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                    <!--End Advanced Tables -->
                </div>
            </div>
        </div>
    </div>

    <!-- CONTENT-WRAPPER SECTION END-->
    <?php include('includes/footer.php');?>
    <!-- FOOTER SECTION END-->
    
    <!-- JAVASCRIPT FILES PLACED AT THE BOTTOM TO REDUCE THE LOADING TIME  -->
    <!-- CORE JQUERY  -->
    <script src="assets/js/jquery-1.10.2.js"></script>
    <!-- BOOTSTRAP SCRIPTS  -->
    <script src="assets/js/bootstrap.js"></script>
    <!-- DATATABLE SCRIPTS  -->
    <script src="assets/js/dataTables/jquery.dataTables.js"></script>
    <script src="assets/js/dataTables/dataTables.bootstrap.js"></script>
    <!-- CUSTOM SCRIPTS  -->
    <script src="assets/js/custom.js"></script>
</body>
</html>