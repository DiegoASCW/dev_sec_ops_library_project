<?php
session_start();
error_reporting(0);
include('includes/config.php');

if(strlen($_SESSION['login'])==0) {   
    header('location:index.php');
} else {
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | View Book Reviews</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    
    <style>
        .review-box {
            border: 1px solid #ddd;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
            background-color: #f9f9f9;
        }
        .review-header {
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            margin-bottom: 10px;
        }
        .star-display {
            color: #FFD700;
        }
        .book-info {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 30px;
        }
        .rating-summary {
            background-color: #fff;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .rating-bar {
            display: flex;
            align-items: center;
            margin-bottom: 5px;
        }
        .rating-bar-fill {
            height: 20px;
            background-color: #FFD700;
            border-radius: 3px;
        }
        .rating-bar-empty {
            height: 20px;
            background-color: #eee;
            border-radius: 3px;
            flex: 1;
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
            
            <?php 
            if(isset($_GET['bookid'])) {
                $bookid = intval($_GET['bookid']);
                
                // Get book details with author and category
                $sql = "SELECT b.*, a.AuthorName, c.CategoryName 
                        FROM tblbooks b 
                        JOIN tblauthors a ON a.id = b.AuthorId 
                        JOIN tblcategory c ON c.id = b.CatId 
                        WHERE b.id=:bookid";
                $query = $dbh->prepare($sql);
                $query->bindParam(':bookid', $bookid, PDO::PARAM_INT);
                $query->execute();
                $book = $query->fetch(PDO::FETCH_OBJ);
                
                if($book) {
                    // Get rating statistics
                    $statsSql = "SELECT 
                                COUNT(*) as TotalReviews,
                                COALESCE(AVG(Rating), 0) as AvgRating,
                                SUM(CASE WHEN Rating = 5 THEN 1 ELSE 0 END) as Five,
                                SUM(CASE WHEN Rating = 4 THEN 1 ELSE 0 END) as Four,
                                SUM(CASE WHEN Rating = 3 THEN 1 ELSE 0 END) as Three,
                                SUM(CASE WHEN Rating = 2 THEN 1 ELSE 0 END) as Two,
                                SUM(CASE WHEN Rating = 1 THEN 1 ELSE 0 END) as One
                                FROM tblreviews WHERE BookId=:bookid";
                    $statsQuery = $dbh->prepare($statsSql);
                    $statsQuery->bindParam(':bookid', $bookid, PDO::PARAM_INT);
                    $statsQuery->execute();
                    $stats = $statsQuery->fetch(PDO::FETCH_OBJ);
            ?>
            
            <div class="row">
                <div class="col-md-12">
                    <!-- Book Information -->
                    <div class="book-info">
                        <h3><?php echo htmlentities($book->BookName);?></h3>
                        <p><strong>Author:</strong> <?php echo htmlentities($book->AuthorName);?></p>
                        <p><strong>Category:</strong> <?php echo htmlentities($book->CategoryName);?></p>
                        <p><strong>ISBN:</strong> <?php echo htmlentities($book->ISBNNumber);?></p>
                        <p><strong>Price:</strong> $<?php echo htmlentities($book->BookPrice);?></p>
                    </div>
                </div>
                
                <!-- Rating Summary -->
                <div class="col-md-4">
                    <div class="rating-summary">
                        <h4>Rating Summary</h4>
                        <div class="text-center">
                            <h1><?php echo number_format($stats->AvgRating, 1);?></h1>
                            <div>
                                <?php 
                                $avgRating = round($stats->AvgRating);
                                for($i = 1; $i <= 5; $i++) {
                                    if($i <= $avgRating) {
                                        echo '<i class="fa fa-star star-display fa-2x"></i>';
                                    } else {
                                        echo '<i class="fa fa-star-o fa-2x"></i>';
                                    }
                                }
                                ?>
                            </div>
                            <p><?php echo $stats->TotalReviews;?> Reviews</p>
                        </div>
                        <hr>
                        
                        <?php 
                        $ratings = array(
                            5 => $stats->Five,
                            4 => $stats->Four,
                            3 => $stats->Three,
                            2 => $stats->Two,
                            1 => $stats->One
                        );
                        
                        foreach($ratings as $star => $count) {
                            $percentage = $stats->TotalReviews > 0 ? ($count / $stats->TotalReviews) * 100 : 0;
                        ?>
                        <div class="rating-bar">
                            <span style="width: 50px;"><?php echo $star;?> <i class="fa fa-star"></i></span>
                            <div style="flex: 1; margin: 0 10px; display: flex;">
                                <div class="rating-bar-fill" style="width: <?php echo $percentage;?>%;"></div>
                                <div class="rating-bar-empty"></div>
                            </div>
                            <span style="width: 50px; text-align: right;"><?php echo $count;?></span>
                        </div>
                        <?php } ?>
                        
                        <hr>
                        <a href="book-reviews.php?bookid=<?php echo $bookid;?>" class="btn btn-primary btn-block">Write a Review</a>
                    </div>
                </div>
                
                <!-- Reviews List -->
                <div class="col-md-8">
                    <h4>Customer Reviews</h4>
                    
                    <?php 
                    // Get all reviews for this book
                    $reviewSql = "SELECT r.*, s.FullName 
                                 FROM tblreviews r 
                                 JOIN tblstudents s ON s.StudentId = r.StudentId 
                                 WHERE r.BookId=:bookid 
                                 ORDER BY r.ReviewDate DESC";
                    $reviewQuery = $dbh->prepare($reviewSql);
                    $reviewQuery->bindParam(':bookid', $bookid, PDO::PARAM_INT);
                    $reviewQuery->execute();
                    $reviews = $reviewQuery->fetchAll(PDO::FETCH_OBJ);
                    
                    if($reviewQuery->rowCount() > 0) {
                        foreach($reviews as $review) {
                    ?>
                    <div class="review-box">
                        <div class="review-header">
                            <strong><?php echo htmlentities($review->FullName);?></strong>
                            <span class="pull-right text-muted">
                                <?php echo date('d M Y', strtotime($review->ReviewDate));?>
                            </span>
                            <div>
                                <?php 
                                for($i = 1; $i <= 5; $i++) {
                                    if($i <= $review->Rating) {
                                        echo '<i class="fa fa-star star-display"></i>';
                                    } else {
                                        echo '<i class="fa fa-star-o"></i>';
                                    }
                                }
                                ?>
                            </div>
                        </div>
                        <p><?php echo htmlentities($review->ReviewText);?></p>
                    </div>
                    <?php }
                    } else { ?>
                        <div class="alert alert-info">
                            <p>No reviews yet. Be the first to review this book!</p>
                            <a href="book-reviews.php?bookid=<?php echo $bookid;?>" class="btn btn-primary">Write a Review</a>
                        </div>
                    <?php } ?>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-12">
                    <a href="book-reviews.php" class="btn btn-default"><i class="fa fa-arrow-left"></i> Back to All Books</a>
                </div>
            </div>
            
            <?php 
                } else {
                    echo '<div class="alert alert-danger">Book not found.</div>';
                    echo '<a href="book-reviews.php" class="btn btn-default">Back to All Books</a>';
                }
            } else {
                header('location:book-reviews.php');
            }
            ?>
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