<?php
session_start();
error_reporting(error_level: 0);

include '../includes/config.php';
include '../includes/sanitize_validation.php';

if (strlen($_SESSION['alogin']) == 0) {
    header('location:index.php');
} else {

    if (isset($_POST['issue'])) {

        # Verifica se o usuário já tem algum livro emprestado
        $studentid = strtoupper($_POST['studentid']);

        $sql = "SELECT id FROM tblissuedbookdetails WHERE StudentID = :studentid AND ReturnDate IS NULL";
        $query = $dbh->prepare($sql);
        $query->bindParam(':studentid', $studentid, PDO::PARAM_STR);
        $query->execute();
        $results = $query->fetchAll(PDO::FETCH_OBJ);

        if (empty($results)) {
            # Realiza INSERT do evento em 'tblissuedbookdetails'
            $bookid = $_POST['bookdetails'];
            $sql = "INSERT INTO tblissuedbookdetails(StudentID, BookId) SELECT :studentid, :bookid FROM tblbooks WHERE id = :bookid AND QuantityLeft > 0;";
            $query = $dbh->prepare($sql);
            $query->bindParam(':studentid', $studentid, PDO::PARAM_STR);
            $query->bindParam(':bookid', $bookid, PDO::PARAM_STR);
            $query->execute();
            $lastInsertId = $dbh->lastInsertId();
    
            # Atualiza qntd de livros disponíveis em 'tblbooks'
            $sql_remove_quantity="UPDATE tblbooks SET QuantityLeft = QuantityLeft - 1 WHERE id = :bookid;";
            $query = $dbh->prepare($sql_remove_quantity);
            $query->bindParam(':bookid', $bookid, PDO::PARAM_STR);
            $query->execute();
            
            if ($lastInsertId) {
                $_SESSION['msg'] = "Book issued successfully";
                #$_SESSION['msg'] = "Book issued successfully";
                header('location:./manage-issued-books.php');
            } else {
                $_SESSION['error'] = "Something went wrong. Please try again";
                header('location:./manage-issued-books.php');
            }
        } else {
            $_SESSION['error'] = "User already has an issued book.";
            header('location:./manage-issued-books.php');
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
        <title>Openshelf | Issue a new Book</title>
        <!-- BOOTSTRAP CORE STYLE  -->
        <link href="assets/css/bootstrap.css" rel="stylesheet" />
        <!-- FONT AWESOME STYLE  -->
        <link href="assets/css/font-awesome.css" rel="stylesheet" />
        <!-- CUSTOM STYLE  -->
        <link href="assets/css/style.css" rel="stylesheet" />
        <!-- GOOGLE FONT -->
        <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
        <script>
            
            // função para capturar nome do estudante à partir do ID
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

            // função para capturar detalhes do livro
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
        <div class="content-wra
    <div class=" content-wrapper">
            <div class="container">
                <div class="row pad-botm">
                    <div class="col-md-12">
                        <h4 class="header-line">Issue a New Book</h4>

                    </div>

                </div>
                <div class="row">
                    <div class="col-md-10 col-sm-6 col-xs-12 col-md-offset-1"">
<div class=" panel panel-info">
                        <div class="panel-heading">
                            Issue a New Book
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">

                                <div class="form-group">
                                    <label>Srtudent id<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="studentid" id="studentid"
                                        onBlur="getstudent()" autocomplete="off" required />
                                </div>

                                <div class="form-group">
                                    <span id="get_student_name" style="font-size:16px;"></span>
                                </div>

                                <div class="form-group">
                                    <label>ISBN Number or Book Title<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="booikid" id="bookid" onBlur="getbook()"
                                        required="required" />
                                </div>

                                <div class="form-group">
                                    <select class="form-control" name="bookdetails" id="get_book_name" readonly>
                                    </select>
                                </div>

                                <button type="submit" name="issue" id="submit" class="btn btn-info">Issue Book </button>

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