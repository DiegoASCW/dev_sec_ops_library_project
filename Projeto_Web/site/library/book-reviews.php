<?php
session_start();
error_reporting(0);
include('includes/config.php');
include('includes/sanitize_validation.php');

if(strlen($_SESSION['login'])==0) {   
    header('location:index.php');
} else {
    // Handle review submission
    if(isset($_POST['submit'])) {
        $bookid = intval($_POST['bookid']);
        $studentid = $_SESSION['stdid'];
        $rating = intval($_POST['rating']);
        $review = $_POST['review'];
        
        // Sanitize review text
        $review = sanitize_string_ascii($review);
        
        // Check for injection attempts
        if(is_injection($review)) {
            $_SESSION['error'] = "Invalid characters detected in review.";
        } else {
            // Check if user has already reviewed this book
            $checksql = "SELECT id FROM tblreviews WHERE BookId=:bookid AND StudentId=:studentid";
            $checkquery = $dbh->prepare($checksql);
            $checkquery->bindParam(':bookid', $bookid, PDO::PARAM_INT);
            $checkquery->bindParam(':studentid', $studentid, PDO::PARAM_STR);
            $checkquery->execute();
            
            if($checkquery->rowCount() > 0) {
                $_SESSION['error'] = "You have already reviewed this book.";
            } else {
                $sql = "INSERT INTO tblreviews(BookId, StudentId, Rating, ReviewText) VALUES(:bookid, :studentid, :rating, :review)";
                $query = $dbh->prepare($sql);
                $query->bindParam(':bookid', $bookid, PDO::PARAM_INT);
                $query->bindParam(':studentid', $studentid, PDO::PARAM_STR);
                $query->bindParam(':rating', $rating, PDO::PARAM_INT);
                $query->bindParam(':review', $review, PDO::PARAM_STR);
                $query->execute();
                
                if($query->rowCount() > 0) {
                    $_SESSION['msg'] = "Review submitted successfully!";
                    header('location:book-reviews.php?bookid='.$bookid);
                } else {
                    $_SESSION['error'] = "Something went wrong. Please try again.";
                }
            }
        }
    }
    
    // Handle review deletion
    if(isset($_GET['del'])) {
        $id = intval($_GET['del']);
        $studentid = $_SESSION['stdid'];
        
        // Verify ownership before deletion
        $sql = "DELETE FROM tblreviews WHERE id=:id AND StudentId=:studentid";
        $query = $dbh->prepare($sql);
        $query->bindParam(':id', $id, PDO::PARAM_INT);
        $query->bindParam(':studentid', $studentid, PDO::PARAM_STR);
        $query->execute();
        
        if($query->rowCount() > 0) {
            $_SESSION['delmsg'] = "Review deleted successfully";
        }
        header('location:book-reviews.php');
    }
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | Book Reviews</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    
    <style>
        .rating {
            display: inline-block;
        }
        .rating input[type="radio"] {
            display: none;
        }
        .rating label {
            float: right;
            cursor: pointer;
            color: #ccc;
            transition: color 0.3s;
        }
        .rating label:before {
            content: '\2605';
            font-size: 30px;
        }
        .rating input[type="radio"]:checked ~ label,
        .rating label:hover,
        .rating label:hover ~ label {
            color: #FFD700;
        }
        .review-box {
            border: 1px solid #ddd;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        .review-header {
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            margin-bottom: 10px;
        }
        .star-display {
            color: #FFD700;
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
                    <h4 class="header-line">Book Reviews</h4>
                </div>
            </div>
            
            <?php if($_SESSION['error']!="") {?>
            <div class="col-md-12">
                <div class="alert alert-danger">
                    <strong>Error :</strong> 
                    <?php echo htmlentities($_SESSION['error']);?>
                    <?php $_SESSION['error']="";?>
                </div>
            </div>
            <?php } ?>
            
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
            
            <div class="row">
                <?php if(isset($_GET['bookid'])) { 
                    $bookid = intval($_GET['bookid']);
                    
                    // Get book details
                    $sql = "SELECT BookName, ISBNNumber FROM tblbooks WHERE id=:bookid";
                    $query = $dbh->prepare($sql);
                    $query->bindParam(':bookid', $bookid, PDO::PARAM_INT);
                    $query->execute();
                    $book = $query->fetch(PDO::FETCH_OBJ);
                    
                    if($book) {
                ?>
                <div class="col-md-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Write a Review for: <strong><?php echo htmlentities($book->BookName);?></strong> (ISBN: <?php echo htmlentities($book->ISBNNumber);?>)
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <input type="hidden" name="bookid" value="<?php echo $bookid;?>" />
                                
                                <div class="form-group">
                                    <label>Rating</label>
                                    <div class="rating">
                                        <input type="radio" name="rating" id="star5" value="5" required>
                                        <label for="star5"></label>
                                        <input type="radio" name="rating" id="star4" value="4" required>
                                        <label for="star4"></label>
                                        <input type="radio" name="rating" id="star3" value="3" required>
                                        <label for="star3"></label>
                                        <input type="radio" name="rating" id="star2" value="2" required>
                                        <label for="star2"></label>
                                        <input type="radio" name="rating" id="star1" value="1" required>
                                        <label for="star1"></label>
                                    </div>
                                </div>
                                
                                <div class="form-group">
                                    <label>Your Review</label>
                                    <textarea class="form-control" name="review" rows="5" required 
                                              placeholder="Share your thoughts about this book..." 
                                              maxlength="1000"></textarea>
                                    <span class="help-block">Maximum 1000 characters</span>
                                </div>
                                
                                <button type="submit" name="submit" class="btn btn-info">Submit Review</button>
                                <a href="book-reviews.php" class="btn btn-default">Back to All Reviews</a>
                            </form>
                        </div>
                    </div>
                </div>
                <?php } 
                } else { ?>
                
                <!-- Book Selection -->
                <div class="col-md-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Select a Book to Review
                        </div>
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered table-hover">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Book Name</th>
                                            <th>Author</th>
                                            <th>ISBN</th>
                                            <th>Avg Rating</th>
                                            <th>Total Reviews</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    <?php 
                                    $sql = "SELECT b.id, b.BookName, b.ISBNNumber, a.AuthorName,
                                            COALESCE(AVG(r.Rating), 0) as AvgRating,
                                            COUNT(r.id) as TotalReviews
                                            FROM tblbooks b
                                            JOIN tblauthors a ON a.id = b.AuthorId
                                            LEFT JOIN tblreviews r ON r.BookId = b.id
                                            GROUP BY b.id
                                            ORDER BY b.BookName";
                                    $query = $dbh->prepare($sql);
                                    $query->execute();
                                    $results = $query->fetchAll(PDO::FETCH_OBJ);
                                    $cnt = 1;
                                    
                                    if($query->rowCount() > 0) {
                                        foreach($results as $result) {
                                    ?>                                      
                                        <tr>
                                            <td><?php echo htmlentities($cnt);?></td>
                                            <td><?php echo htmlentities($result->BookName);?></td>
                                            <td><?php echo htmlentities($result->AuthorName);?></td>
                                            <td><?php echo htmlentities($result->ISBNNumber);?></td>
                                            <td>
                                                <?php 
                                                $avgRating = round($result->AvgRating, 1);
                                                for($i = 1; $i <= 5; $i++) {
                                                    if($i <= $avgRating) {
                                                        echo '<i class="fa fa-star star-display"></i>';
                                                    } else {
                                                        echo '<i class="fa fa-star-o"></i>';
                                                    }
                                                }
                                                echo " (" . $avgRating . ")";
                                                ?>
                                            </td>
                                            <td><?php echo htmlentities($result->TotalReviews);?></td>
                                            <td>
                                                <a href="book-reviews.php?bookid=<?php echo htmlentities($result->id);?>" 
                                                   class="btn btn-primary btn-xs">Write Review</a>
                                                <a href="view-book-reviews.php?bookid=<?php echo htmlentities($result->id);?>" 
                                                   class="btn btn-info btn-xs">View Reviews</a>
                                            </td>
                                        </tr>
                                    <?php $cnt++; }} ?>                                      
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                    
                    <!-- My Reviews -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            My Reviews
                        </div>
                        <div class="panel-body">
                            <?php 
                            $studentid = $_SESSION['stdid'];
                            $sql = "SELECT r.*, b.BookName, b.ISBNNumber 
                                    FROM tblreviews r 
                                    JOIN tblbooks b ON b.id = r.BookId 
                                    WHERE r.StudentId=:studentid 
                                    ORDER BY r.ReviewDate DESC";
                            $query = $dbh->prepare($sql);
                            $query->bindParam(':studentid', $studentid, PDO::PARAM_STR);
                            $query->execute();
                            $results = $query->fetchAll(PDO::FETCH_OBJ);
                            
                            if($query->rowCount() > 0) {
                                foreach($results as $result) {
                            ?>
                            <div class="review-box">
                                <div class="review-header">
                                    <h5><?php echo htmlentities($result->BookName);?> 
                                        <small>(ISBN: <?php echo htmlentities($result->ISBNNumber);?>)</small>
                                        <span class="pull-right">
                                            <a href="book-reviews.php?del=<?php echo htmlentities($result->id);?>" 
                                               onclick="return confirm('Are you sure you want to delete this review?');"
                                               class="btn btn-danger btn-xs">Delete</a>
                                        </span>
                                    </h5>
                                    <div>
                                        <?php 
                                        for($i = 1; $i <= 5; $i++) {
                                            if($i <= $result->Rating) {
                                                echo '<i class="fa fa-star star-display"></i>';
                                            } else {
                                                echo '<i class="fa fa-star-o"></i>';
                                            }
                                        }
                                        ?>
                                        <small class="text-muted"> - <?php echo date('d M Y', strtotime($result->ReviewDate));?></small>
                                    </div>
                                </div>
                                <p><?php echo htmlentities($result->ReviewText);?></p>
                            </div>
                            <?php }
                            } else { ?>
                                <p>You haven't written any reviews yet.</p>
                            <?php } ?>
                        </div>
                    </div>
                </div>
                <?php } ?>
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
    <!-- CUSTOM SCRIPTS  -->
    <script src="assets/js/custom.js"></script>
</body>
</html>
<?php } ?>