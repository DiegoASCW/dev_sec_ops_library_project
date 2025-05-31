<?php
session_start();
error_reporting(1);

include '../includes/config.php';
include '../includes/sanitize_validation.php';

if (strlen($_SESSION['alogin']) == 0) {
    header('location:index.php');
} else {
    if (isset($_POST['return'])) {
        $rid = intval($_GET['rid']);
        $fine = $_POST['fine'];
        $rstatus = 1;

        // Registra novo evento de devolução de livro
        $sql = "UPDATE tblissuedbookdetails SET fine=:fine, RetrunStatus=:rstatus WHERE id=:rid";
        $query = $dbh->prepare($sql);
        $query->bindParam(':rid', $rid, PDO::PARAM_INT);
        $query->bindParam(':fine', $fine, PDO::PARAM_STR);
        $query->bindParam(':rstatus', $rstatus, PDO::PARAM_INT);
        $query->execute();

        // Adiciona +1 à quantidade de livros disponíveis
        $bookid = intval($_GET['bookid']);
        $sql_add_quantity = "UPDATE tblbooks SET QuantityLeft = QuantityLeft + 1 WHERE id = :bookid";
        $query = $dbh->prepare($sql_add_quantity);
        $query->bindParam(':bookid', $bookid, PDO::PARAM_INT);
        $query->execute();

        $_SESSION['msg'] = "Book ID '$bookid' Returned successfully";
        header('location:manage-issued-books.php');
    } elseif (isset($_POST['cancel'])) {
        $rid = intval($_GET['rid']);

        // Deleta registro de empréstimo 
        $sql = "DELETE FROM tblissuedbookdetails WHERE id=:rid";
        $query = $dbh->prepare($sql);
        $query->bindParam(':rid', $rid, PDO::PARAM_INT);
        $query->execute();

        // Adiciona +1 à quantidade de livros disponíveis
        $bookid = intval($_GET['bookid']);
        $sql_add_quantity = "UPDATE tblbooks SET QuantityLeft = QuantityLeft + 1 WHERE id = :bookid";
        $query = $dbh->prepare($sql_add_quantity);
        $query->bindParam(':bookid', $bookid, PDO::PARAM_INT);
        $query->execute();

        $_SESSION['msg'] = "Book ID '$bookid' has the issue canceled";
        header('location:manage-issued-books.php');
    }
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | Issued Book Details</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    <script>
        // Function for get student name
        function getstudent() {
            $("#loaderIcon").show();
            jQuery.ajax({
                url: "get_student.php",
                data: 'studentid=' + $("#studentid").val(),
                type: "POST",
                success: function (data) {
                    $("#get_student_name").html(data);
                    $("#loaderIcon").hide();
                },
                error: function () { }
            });
        }

        // Function for book details
        function getbook() {
            $("#loaderIcon").show();
            jQuery.ajax({
                url: "get_book.php",
                data: 'bookid=' + $("#bookid").val(),
                type: "POST",
                success: function (data) {
                    $("#get_book_name").html(data);
                    $("#loaderIcon").hide();
                },
                error: function () { }
            });
        }
    </script>
    <style type="text/css">
        .others {
            color: red;
        }
    </style>
</head>

<body>
    <!------MENU SECTION START-->
    <?php include('includes/header.php'); ?>
    <!-- MENU SECTION END-->
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">Issued Book Details</h4>
                </div>
            </div>
            <div class="row">
                <div class="col-md-10 col-sm-6 col-xs-12 col-md-offset-1">
                    <div class="panel panel-info">
                        <div class="panel-heading">
                            Issued Book Details
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <?php
                                $rid = intval($_GET['rid']);
                                $sql = "SELECT tblstudents.FullName, tblbooks.BookName, tblbooks.ISBNNumber, tblissuedbookdetails.IssuesDate, tblissuedbookdetails.ReturnDate, tblissuedbookdetails.id as rid, tblissuedbookdetails.fine, tblissuedbookdetails.RetrunStatus 
                                        FROM tblissuedbookdetails 
                                        JOIN tblstudents ON tblstudents.StudentId = tblissuedbookdetails.StudentId 
                                        JOIN tblbooks ON tblbooks.id = tblissuedbookdetails.BookId 
                                        WHERE tblissuedbookdetails.id = :rid";

                                $query = $dbh->prepare($sql);
                                $query->bindParam(':rid', $rid, PDO::PARAM_INT);
                                $query->execute();
                                $results = $query->fetchAll(PDO::FETCH_OBJ);

                                if ($query->rowCount() > 0) {
                                    foreach ($results as $result) {
                                ?>
                                        <div class="form-group">
                                            <label>Student Name:</label>
                                            <?php echo htmlentities($result->FullName); ?>
                                        </div>

                                        <div class="form-group">
                                            <label>Book Name:</label>
                                            <?php echo htmlentities($result->BookName); ?>
                                        </div>

                                        <div class="form-group">
                                            <label>ISBN:</label>
                                            <?php echo htmlentities($result->ISBNNumber); ?>
                                        </div>

                                        <div class="form-group">
                                            <label>Book Issued Date:</label>
                                            <?php echo htmlentities($result->IssuesDate); ?>
                                        </div>

                                        <div class="form-group">
                                            <label>Book Returned Date:</label>
                                            <?php echo $result->ReturnDate == "" ? "Not Returned Yet" : htmlentities($result->ReturnDate); ?>
                                        </div>

                                        <div class="form-group">
                                            <label>Expected Fine:</label>
                                            <?php 
                                            // Cálculo da multa ($10 por cada 15 dias de atraso)
                                            $days_per_fine = 15;
                                            $fine_per_period = 10;
                                            $seconds_per_day = 86400;
                                            
                                            if ($result->ReturnDate == "") {
                                                $days_diff = (time() - strtotime($result->IssuesDate)) / $seconds_per_day;
                                            } else {
                                                $days_diff = (strtotime($result->ReturnDate) - strtotime($result->IssuesDate)) / $seconds_per_day;
                                            }
                                            
                                            $fine_value = ($days_diff / $days_per_fine) * $fine_per_period;
                                            echo "$" . number_format(max(0, $fine_value), 2);
                                            ?>
                                        </div>

                                        <div class="form-group">
                                            <label>Input Fine:</label>
                                            <?php if ($result->fine == "") { ?>
                                                <input class="form-control" type="text" name="fine" id="fine" />
                                            <?php } else {
                                                echo htmlentities($result->fine);
                                            } ?>
                                        </div>
                                        
                                        <?php if ($result->RetrunStatus == 0) { ?>
                                            <button type="submit" name="return" class="btn btn-info">Return Book</button>
                                            <button type="submit" name="cancel" class="btn btn-danger">Cancel Issue</button>
                                        <?php } ?>
                                </div>
                                <?php 
                                    }
                                } ?>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- CONTENT-WRAPPER SECTION END-->
    <?php include('includes/footer.php'); ?>
    <!-- FOOTER SECTION END-->
    <script src="assets/js/jquery-1.10.2.js"></script>
    <script src="assets/js/bootstrap.js"></script>
    <script src="assets/js/custom.js"></script>
</body>

</html>
<?php } ?>