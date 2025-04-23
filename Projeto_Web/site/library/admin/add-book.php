<?php
session_start();
error_reporting(0);

include '../includes/config.php';
include '../includes/sanitize_validation.php';

if (strlen($_SESSION['alogin']) == 0) {
    header('location:index.php');
} else {

    if (isset($_POST['add'])) {
        $bookname = sanitize_string_ascii($_POST['bookname']);
        if (is_injection($bookname)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }

        $description = sanitize_string_ascii($_POST['description']);
        if (is_injection($description)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }

        $category = sanitize_string_ascii($_POST['category']);
        if (is_injection($category)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }

        $author = sanitize_string_ascii($_POST['author']);
        if (is_injection($author)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }

        $quantitytotal = sanitize_string_ascii($_POST['quantitytotal']);
        if (is_injection($quantitytotal)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }

        $isbn = sanitize_string_ascii($_POST['isbn']);
        if (is_injection($isbn)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }

        $price = sanitize_string_ascii($_POST['price']);
        if (is_injection($price)) {
            die('ERRO: Entrada inválida detectada no campo...');
        }
        //echo 'Bookname ', $bookname, '      Description,', $description, '      Category', $category,  '      Author', $author, '      QuantityTotal', $quantitytotal, '      ISBN', $isbn, '      Price', $price;


        $sql = "INSERT INTO  tblbooks(BookName,Description,CatId,AuthorId,QuantityTotal,QuantityLeft,ISBNNumber,BookPrice) VALUES(:bookname,:description,:category,:author,:quantitytotal,:quantitytotal,:isbn,:price)";

        $query = $dbh->prepare($sql);
        $query->bindParam(':bookname', $bookname, PDO::PARAM_STR);
        $query->bindParam(':description', $description, PDO::PARAM_STR);
        $query->bindParam(':category', $category, PDO::PARAM_STR);
        $query->bindParam(':author', $author, PDO::PARAM_STR);
        $query->bindParam(':quantitytotal', $quantitytotal, PDO::PARAM_STR);
        $query->bindParam(':isbn', $isbn, PDO::PARAM_STR);
        $query->bindParam(':price', $price, PDO::PARAM_STR);
        $query->execute();

        $lastInsertId = $dbh->lastInsertId();

        echo $_SESSION['msg'];
        if ($lastInsertId) {
            $_SESSION['msg'] = "Book Listed successfully";
            header('location:manage-books.php');
        } else {
            $_SESSION['error'] = "Something went wrong. Please try again";
            header('location:manage-books.php');
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
        <title>Openshelf | Add Book</title>
        <!-- BOOTSTRAP CORE STYLE  -->
        <link href="assets/css/bootstrap.css" rel="stylesheet" />
        <!-- FONT AWESOME STYLE  -->
        <link href="assets/css/font-awesome.css" rel="stylesheet" />
        <!-- CUSTOM STYLE  -->
        <link href="assets/css/style.css" rel="stylesheet" />
        <!-- GOOGLE FONT -->
        <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
    </head>

    <body>
        <?php include('includes/header.php'); ?>
        <div class="content-wrapper">
            <div class="container">
                <div class="row pad-botm">
                    <div class="col-md-12">
                        <h4 class="header-line">Add Book</h4>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3"">
                    <div class=" panel panel-info">
                        <div class="panel-heading">
                            Book Info
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">

                                <div class="form-group">
                                    <label>Book Name<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="bookname" autocomplete="off" required />
                                </div>

                                <div class="form-group">
                                    <label>Descrição (até 255 caracteres)<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="description" autocomplete="off"
                                        required />
                                </div>

                                <div class="form-group">
                                    <label> Category<span style="color:red;">*</span></label>
                                    <select class="form-control" name="category" required="required">
                                        <option value=""> Select Category</option>

                                        <!-- Lista as categorias de livros da tabela 'tblcategory' -->
                                        <?php
                                        $status = 1;
                                        $sql = "SELECT * from  tblcategory where Status=:status";
                                        $query = $dbh->prepare($sql);
                                        $query->bindParam(':status', $status, PDO::PARAM_STR);
                                        $query->execute();
                                        $results = $query->fetchAll(PDO::FETCH_OBJ);
                                        $cnt = 1;
                                        if ($query->rowCount() > 0) {
                                            foreach ($results as $result) { ?>
                                                <option value="<?php echo htmlentities($result->id); ?>">
                                                    <?php echo htmlentities($result->CategoryName); ?>
                                                </option>
                                            <?php }
                                        } ?>
                                    </select>
                                </div>

                                <div class="form-group">
                                    <label> Author<span style="color:red;">*</span></label>
                                    <select class="form-control" name="author" required="required">
                                        <option value=""> Select Author</option>

                                        <!-- Lista os autores da tabela 'tblauthors' -->
                                        <?php
                                        $sql = "SELECT * from  tblauthors ";
                                        $query = $dbh->prepare($sql);
                                        $query->execute();
                                        $results = $query->fetchAll(PDO::FETCH_OBJ);
                                        $cnt = 1;
                                        if ($query->rowCount() > 0) {
                                            foreach ($results as $result) { ?>
                                                <option value="<?php echo htmlentities($result->id); ?>">
                                                    <?php echo htmlentities($result->AuthorName); ?>
                                                </option>
                                            <?php }
                                        } ?>
                                    </select>
                                </div>

                                <div class="form-group">
                                    <label>Quantity Total<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="quantitytotal" required="required"
                                        autocomplete="off" />
                                </div>

                                <div class="form-group">
                                    <label>ISBN Number<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="isbn" required="required"
                                        autocomplete="off" />
                                    <p class="help-block">An ISBN is an International Standard Book Number.ISBN Must be
                                        unique</p>
                                </div>

                                <div class="form-group">
                                    <label>Price<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="price" autocomplete="off"
                                        required="required" />
                                </div>

                                <button type="submit" name="add" class="btn btn-info">Add </button>

                            </form>
                        </div>
                    </div>
                </div>

            </div>

        </div>
        </div>
        <?php include('includes/footer.php'); ?>
        <!-- CORE JQUERY  -->
        <script src="assets/js/jquery-1.10.2.js"></script>
        <!-- BOOTSTRAP SCRIPTS  -->
        <script src="assets/js/bootstrap.js"></script>
        <!-- CUSTOM SCRIPTS  -->
        <script src="assets/js/custom.js"></script>
    </body>

    </html>
<?php } ?>