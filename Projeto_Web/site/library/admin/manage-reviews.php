<?php
session_start();
error_reporting(0);
include('includes/config.php');

if(strlen($_SESSION['alogin'])==0) {   
    header('location:index.php');
} else {
    // Handle review deletion
    if(isset($_GET['del'])) {
        $id = intval($_GET['del']);
        $sql = "DELETE FROM tblreviews WHERE id=:id";
        $query = $dbh->prepare($sql);
        $query->bindParam(':id', $id, PDO::PARAM_INT);
        $query->execute();
        $_SESSION['delmsg'] = "Review deleted successfully";
        header('location:manage-reviews.php');
    }
    
    // Handle review approval/disapproval
    if(isset($_GET['approve'])) {
        $id = intval($_GET['approve']);
        $status = 1;
        $sql = "UPDATE tblreviews SET Status=:status WHERE id=:id";
        $query = $dbh->prepare($sql);
        $query->bindParam(':status', $status, PDO::PARAM_INT);
        $query->bindParam(':id', $id, PDO::PARAM_INT);
        $query->execute();
        $_SESSION['msg'] = "Review approved successfully";
        header('location:manage-reviews.php');
    }
    
    if(isset($_GET['disapprove'])) {
        $id = intval($_GET['disapprove']);
        $status = 0;
        $sql = "UPDATE tblreviews SET Status=:status WHERE id=:id";
        $query = $dbh->prepare($sql);
        $query->bindParam(':status', $status, PDO::PARAM_INT);
        $query->bindParam(':id', $id, PDO::PARAM_INT);
        $query->execute();
        $_SESSION['msg'] = "Review disapproved successfully";
        header('location:manage-reviews.php');
    }
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | Manage Reviews</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- DATATABLE STYLE  -->
    <link href="assets/js/dataTables/dataTables.bootstrap.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    
    <style>
        .star-display {
            color: #FFD700;
        }
        .review-text {
            max-width: 300px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .status-approved {
            color: #5cb85c;
            font-weight: bold;
        }
        .status-pending {
            color: #f0ad4e;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <!------MENU SECTION START-->
    <?php include('includes/header.php');?>
    <!-- MENU SECTION END-->
    
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">Manage Reviews</h4>
                </div>
            </div>
            
            <div class="row">
                <?php if($_SESSION['msg']!="") {?>
                <div class="col-md-12">
                    <div class="alert alert-success">
                        <strong>Success :</strong> 
                        <?php echo htmlentities($_SESSION['msg']);?>
                        <?php $_SESSION['msg']="";?>
                    </div>
                </div>
                <?php } ?>
                
                <?php if($_SESSION['delmsg']!="") {?>
                <div class="col-md-12">
                    <div class="alert alert-info">
                        <strong>Info :</strong> 
                        <?php echo htmlentities($_SESSION['delmsg']);?>
                        <?php $_SESSION['delmsg']="";?>
                    </div>
                </div>
                <?php } ?>
            </div>
            
            <div class="row">
                <div class="col-md-12">
                    <!-- Review Statistics -->
                    <div class="row" style="margin-bottom: 20px;">
                        <?php
                        // Get statistics
                        $totalSql = "SELECT COUNT(*) as total FROM tblreviews";
                        $totalQuery = $dbh->prepare($totalSql);
                        $totalQuery->execute();
                        $totalReviews = $totalQuery->fetch(PDO::FETCH_OBJ)->total;
                        
                        $approvedSql = "SELECT COUNT(*) as approved FROM tblreviews WHERE Status=1";
                        $approvedQuery = $dbh->prepare($approvedSql);
                        $approvedQuery->execute();
                        $approvedReviews = $approvedQuery->fetch(PDO::FETCH_OBJ)->approved;
                        
                        $pendingSql = "SELECT COUNT(*) as pending FROM tblreviews WHERE Status=0";
                        $pendingQuery = $dbh->prepare($pendingSql);
                        $pendingQuery->execute();
                        $pendingReviews = $pendingQuery->fetch(PDO::FETCH_OBJ)->pending;
                        ?>
                        
                        <div class="col-md-4">
                            <div class="alert alert-info back-widget-set text-center">
                                <i class="fa fa-comments fa-5x"></i>
                                <h3><?php echo htmlentities($totalReviews); ?></h3>
                                Total Reviews
                            </div>
                        </div>
                        
                        <div class="col-md-4">
                            <div class="alert alert-success back-widget-set text-center">
                                <i class="fa fa-check-circle fa-5x"></i>
                                <h3><?php echo htmlentities($approvedReviews); ?></h3>
                                Approved Reviews
                            </div>
                        </div>
                        
                        <div class="col-md-4">
                            <div class="alert alert-warning back-widget-set text-center">
                                <i class="fa fa-clock-o fa-5x"></i>
                                <h3><?php echo htmlentities($pendingReviews); ?></h3>
                                Pending Reviews
                            </div>
                        </div>
                    </div>
                    
                    <!-- Reviews Table -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            All Reviews
                        </div>
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered table-hover" id="dataTables-example">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Book</th>
                                            <th>Student</th>
                                            <th>Rating</th>
                                            <th>Review</th>
                                            <th>Date</th>
                                            <th>Status</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    <?php 
                                    $sql = "SELECT r.*, b.BookName, s.FullName, s.StudentId as StdId
                                            FROM tblreviews r
                                            JOIN tblbooks b ON b.id = r.BookId
                                            JOIN tblstudents s ON s.StudentId = r.StudentId
                                            ORDER BY r.ReviewDate DESC";
                                    $query = $dbh->prepare($sql);
                                    $query->execute();
                                    $results = $query->fetchAll(PDO::FETCH_OBJ);
                                    $cnt = 1;
                                    
                                    if($query->rowCount() > 0) {
                                        foreach($results as $result) {
                                    ?>                                      
                                        <tr class="odd gradeX">
                                            <td class="center"><?php echo htmlentities($cnt);?></td>
                                            <td><?php echo htmlentities($result->BookName);?></td>
                                            <td><?php echo htmlentities($result->FullName);?><br>
                                                <small class="text-muted">(<?php echo htmlentities($result->StdId);?>)</small>
                                            </td>
                                            <td class="center">
                                                <?php 
                                                for($i = 1; $i <= 5; $i++) {
                                                    if($i <= $result->Rating) {
                                                        echo '<i class="fa fa-star star-display"></i>';
                                                    } else {
                                                        echo '<i class="fa fa-star-o"></i>';
                                                    }
                                                }
                                                ?>
                                            </td>
                                            <td>
                                                <div class="review-text" title="<?php echo htmlentities($result->ReviewText);?>">
                                                    <?php echo htmlentities($result->ReviewText);?>
                                                </div>
                                                <a href="#" onclick="showFullReview('<?php echo addslashes(htmlentities($result->ReviewText));?>')">
                                                    <small>Read more</small>
                                                </a>
                                            </td>
                                            <td class="center"><?php echo date('d-M-Y', strtotime($result->ReviewDate));?></td>
                                            <td class="center">
                                                <?php if($result->Status == 1) { ?>
                                                    <span class="status-approved">Approved</span>
                                                <?php } else { ?>
                                                    <span class="status-pending">Pending</span>
                                                <?php } ?>
                                            </td>
                                            <td class="center">
                                                <?php if($result->Status == 0) { ?>
                                                    <a href="manage-reviews.php?approve=<?php echo htmlentities($result->id);?>" 
                                                       class="btn btn-success btn-xs" 
                                                       onclick="return confirm('Are you sure you want to approve this review?');">
                                                        <i class="fa fa-check"></i> Approve
                                                    </a>
                                                <?php } else { ?>
                                                    <a href="manage-reviews.php?disapprove=<?php echo htmlentities($result->id);?>" 
                                                       class="btn btn-warning btn-xs" 
                                                       onclick="return confirm('Are you sure you want to disapprove this review?');">
                                                        <i class="fa fa-times"></i> Disapprove
                                                    </a>
                                                <?php } ?>
                                                <a href="manage-reviews.php?del=<?php echo htmlentities($result->id);?>" 
                                                   class="btn btn-danger btn-xs" 
                                                   onclick="return confirm('Are you sure you want to delete this review?');">
                                                    <i class="fa fa-trash"></i> Delete
                                                </a>
                                            </td>
                                        </tr>
                                    <?php $cnt++; }} ?>                                      
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal for full review text -->
    <div class="modal fade" id="reviewModal" tabindex="-1" role="dialog" aria-labelledby="reviewModalLabel">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                    <h4 class="modal-title" id="reviewModalLabel">Full Review</h4>
                </div>
                <div class="modal-body" id="reviewModalBody">
                    <!-- Review text will be inserted here -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
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
    
    <script>
        $(document).ready(function () {
            $('#dataTables-example').dataTable({
                "order": [[ 5, "desc" ]] // Sort by date column by default
            });
        });
        
        function showFullReview(reviewText) {
            document.getElementById('reviewModalBody').textContent = reviewText;
            $('#reviewModal').modal('show');
        }
    </script>
</body>
</html>
<?php } ?>