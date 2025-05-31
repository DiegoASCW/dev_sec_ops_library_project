<?php
session_start();
error_reporting(0);

include '../includes/config.php';

// Check if user is logged in
if(strlen($_SESSION['alogin'])==0) {   
    header('location:index.php');
    exit();
}

// Handle book deletion
if(isset($_GET['del'])) {
    $id = intval($_GET['del']); // Convert to integer for security
    
    if($id > 0) { // Validate ID
        $sql = "DELETE FROM tblbooks WHERE id=:id";
        $query = $dbh->prepare($sql);
        $query->bindParam(':id', $id, PDO::PARAM_INT);
        
        if($query->execute()) {
            $_SESSION['delmsg'] = "Book deleted successfully";
        } else {
            $_SESSION['error'] = "Error deleting book";
        }
    } else {
        $_SESSION['error'] = "Invalid book ID";
    }
    
    header('location:manage-books.php');
    exit();
}

// Initialize session variables if not set
if(!isset($_SESSION['error'])) $_SESSION['error'] = "";
if(!isset($_SESSION['msg'])) $_SESSION['msg'] = "";
if(!isset($_SESSION['updatemsg'])) $_SESSION['updatemsg'] = "";
if(!isset($_SESSION['delmsg'])) $_SESSION['delmsg'] = "";
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | Manage Books</title>
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
                    <h4 class="header-line">Manage Books</h4>
                </div>
                <div class="row">
                    <?php if(!empty($_SESSION['error'])) { ?>
                        <div class="col-md-6">
                            <div class="alert alert-danger">
                                <strong>Error:</strong> 
                                <?php echo htmlentities($_SESSION['error']);?>
                                <?php $_SESSION['error'] = ""; ?>
                            </div>
                        </div>
                    <?php } ?>
                    
                    <?php if(!empty($_SESSION['msg'])) { ?>
                        <div class="col-md-6">
                            <div class="alert alert-success">
                                <strong>Success:</strong> 
                                <?php echo htmlentities($_SESSION['msg']);?>
                                <?php $_SESSION['msg'] = ""; ?>
                            </div>
                        </div>
                    <?php } ?>
                    
                    <?php if(!empty($_SESSION['updatemsg'])) { ?>
                        <div class="col-md-6">
                            <div class="alert alert-success">
                                <strong>Success:</strong> 
                                <?php echo htmlentities($_SESSION['updatemsg']);?>
                                <?php $_SESSION['updatemsg'] = ""; ?>
                            </div>
                        </div>
                    <?php } ?>

                    <?php if(!empty($_SESSION['delmsg'])) { ?>
                        <div class="col-md-6">
                            <div class="alert alert-success">
                                <strong>Success:</strong> 
                                <?php echo htmlentities($_SESSION['delmsg']);?>
                                <?php $_SESSION['delmsg'] = ""; ?>
                            </div>
                        </div>
                    <?php } ?>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-12">
                    <!-- Advanced Tables -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                           Books Listing
                        </div>
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered table-hover" id="dataTables-example">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Book Name</th>
                                            <th>Category</th>
                                            <th>Author</th>
                                            <th>ISBN</th>
                                            <th>Quantity Left</th>
                                            <th>Price</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
<?php 
$sql = "SELECT tblbooks.BookName, tblcategory.CategoryName, tblauthors.AuthorName, 
               tblbooks.ISBNNumber, tblbooks.QuantityLeft, tblbooks.BookPrice, 
               tblbooks.id as bookid 
        FROM tblbooks 
        JOIN tblcategory ON tblcategory.id = tblbooks.CatId  
        JOIN tblauthors ON tblauthors.id = tblbooks.AuthorId";
        
$query = $dbh->prepare($sql);
$query->execute();
$results = $query->fetchAll(PDO::FETCH_OBJ);
$cnt = 1;

if($query->rowCount() > 0) {
    foreach($results as $result) { ?>                                      
                                        <tr class="odd gradeX">
                                            <td class="center"><?php echo htmlentities($cnt);?></td>
                                            <td class="center"><?php echo htmlentities($result->BookName);?></td>
                                            <td class="center"><?php echo htmlentities($result->CategoryName);?></td>
                                            <td class="center"><?php echo htmlentities($result->AuthorName);?></td>
                                            <td class="center"><?php echo htmlentities($result->ISBNNumber);?></td>
                                            <td class="center"><?php echo htmlentities($result->QuantityLeft);?></td>
                                            <td class="center"><?php echo htmlentities($result->BookPrice);?></td>
                                            <td class="center">
                                                <a href="edit-book.php?bookid=<?php echo htmlentities($result->bookid);?>" class="btn btn-primary">
                                                    <i class="fa fa-edit"></i> Edit
                                                </a>
                                                <a href="manage-books.php?del=<?php echo htmlentities($result->bookid);?>" 
                                                   onclick="return confirm('Are you sure you want to delete this book?');" 
                                                   class="btn btn-danger">
                                                    <i class="fa fa-trash"></i> Delete
                                                </a>
                                            </td>
                                        </tr>
                                    <?php $cnt++; 
    }
} else { ?>
                                        <tr>
                                            <td colspan="8" class="center">No books found</td>
                                        </tr>
<?php } ?>                                      
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