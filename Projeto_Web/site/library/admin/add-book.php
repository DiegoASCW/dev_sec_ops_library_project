<?php
session_start();
error_reporting(0);

include '../includes/config.php';

// Verificar autenticação
if (strlen($_SESSION['alogin']) == 0) {
    header('location:index.php');
    exit();
}

// Gerar token CSRF se não existir
if (!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

if (isset($_POST['add'])) {
    // Verificar token CSRF
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $_SESSION['error'] = "Token de segurança inválido";
        header('location:manage-books.php');
        exit();
    }
    
    // Validar e sanitizar dados
    $bookname = trim($_POST['bookname']);
    $description = trim($_POST['description']);
    $category = $_POST['category'];
    $author = $_POST['author'];
    $quantitytotal = $_POST['quantitytotal'];
    $isbn = trim($_POST['isbn']);
    $price = $_POST['price'];
    
    // Validações
    $errors = [];
    
    if (empty($bookname) || strlen($bookname) > 255) {
        $errors[] = "Nome do livro inválido (máximo 255 caracteres)";
    }
    
    if (empty($description) || strlen($description) > 255) {
        $errors[] = "Descrição inválida (máximo 255 caracteres)";
    }
    
    if (empty($category) || !is_numeric($category)) {
        $errors[] = "Categoria inválida";
    }
    
    if (empty($author) || !is_numeric($author)) {
        $errors[] = "Autor inválido";
    }
    
    if (empty($quantitytotal) || !is_numeric($quantitytotal) || $quantitytotal < 0) {
        $errors[] = "Quantidade total inválida";
    }
    
    if (empty($isbn) || strlen($isbn) > 50) {
        $errors[] = "ISBN inválido (máximo 50 caracteres)";
    }
    
    if (empty($price) || !is_numeric($price) || $price < 0) {
        $errors[] = "Preço inválido";
    }
    
    if (!empty($errors)) {
        $_SESSION['error'] = implode(', ', $errors);
        header('location:manage-books.php');
        exit();
    }
    
    try {
        // Verificar se ISBN já existe
        $checkSql = "SELECT ISBNNumber FROM tblbooks WHERE ISBNNumber = :isbn";
        $checkQuery = $dbh->prepare($checkSql);
        $checkQuery->bindParam(':isbn', $isbn, PDO::PARAM_STR);
        $checkQuery->execute();
        
        if ($checkQuery->rowCount() > 0) {
            $_SESSION['error'] = "Este ISBN já existe";
            header('location:manage-books.php');
            exit();
        }
        
        // Verificar se categoria existe
        $catCheckSql = "SELECT id FROM tblcategory WHERE id = :category AND Status = 1";
        $catCheckQuery = $dbh->prepare($catCheckSql);
        $catCheckQuery->bindParam(':category', $category, PDO::PARAM_INT);
        $catCheckQuery->execute();
        
        if ($catCheckQuery->rowCount() == 0) {
            $_SESSION['error'] = "Categoria não encontrada ou inativa";
            header('location:manage-books.php');
            exit();
        }
        
        // Verificar se autor existe
        $authCheckSql = "SELECT id FROM tblauthors WHERE id = :author";
        $authCheckQuery = $dbh->prepare($authCheckSql);
        $authCheckQuery->bindParam(':author', $author, PDO::PARAM_INT);
        $authCheckQuery->execute();
        
        if ($authCheckQuery->rowCount() == 0) {
            $_SESSION['error'] = "Autor não encontrado";
            header('location:manage-books.php');
            exit();
        }
        
        // Inserir livro
        $sql = "INSERT INTO tblbooks(BookName, Description, CatId, AuthorId, QuantityTotal, QuantityLeft, ISBNNumber, BookPrice) 
                VALUES(:bookname, :description, :category, :author, :quantitytotal, :quantitytotal, :isbn, :price)";
        
        $query = $dbh->prepare($sql);
        $query->bindParam(':bookname', $bookname, PDO::PARAM_STR);
        $query->bindParam(':description', $description, PDO::PARAM_STR);
        $query->bindParam(':category', $category, PDO::PARAM_INT);
        $query->bindParam(':author', $author, PDO::PARAM_INT);
        $query->bindParam(':quantitytotal', $quantitytotal, PDO::PARAM_INT);
        $query->bindParam(':isbn', $isbn, PDO::PARAM_STR);
        $query->bindParam(':price', $price, PDO::PARAM_STR);
        $query->execute();
        
        $lastInsertId = $dbh->lastInsertId();
        
        if ($lastInsertId) {
            $_SESSION['msg'] = "Livro adicionado com sucesso";
            header('location:manage-books.php');
            exit();
        } else {
            $_SESSION['error'] = "Erro ao adicionar livro";
            header('location:manage-books.php');
            exit();
        }
        
    } catch (PDOException $e) {
        $_SESSION['error'] = "Erro no banco de dados: " . $e->getMessage();
        header('location:manage-books.php');
        exit();
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
    <title>Openshelf | Adicionar Livro</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
</head>

<body>
    <?php include('includes/header.php'); ?>
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">Adicionar Livro</h4>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                    <div class="panel panel-info">
                        <div class="panel-heading">
                            Informações do Livro
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>" />

                                <div class="form-group">
                                    <label>Nome do Livro<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="bookname" 
                                           maxlength="255" autocomplete="off" required />
                                </div>

                                <div class="form-group">
                                    <label>Descrição (até 255 caracteres)<span style="color:red;">*</span></label>
                                    <textarea class="form-control" name="description" rows="3" 
                                              maxlength="255" required></textarea>
                                </div>

                                <div class="form-group">
                                    <label>Categoria<span style="color:red;">*</span></label>
                                    <select class="form-control" name="category" required>
                                        <option value="">Selecione uma Categoria</option>
                                        <?php
                                        $status = 1;
                                        $sql = "SELECT * FROM tblcategory WHERE Status = :status ORDER BY CategoryName";
                                        $query = $dbh->prepare($sql);
                                        $query->bindParam(':status', $status, PDO::PARAM_INT);
                                        $query->execute();
                                        $results = $query->fetchAll(PDO::FETCH_OBJ);
                                        
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
                                    <label>Autor<span style="color:red;">*</span></label>
                                    <select class="form-control" name="author" required>
                                        <option value="">Selecione um Autor</option>
                                        <?php
                                        $sql = "SELECT * FROM tblauthors ORDER BY AuthorName";
                                        $query = $dbh->prepare($sql);
                                        $query->execute();
                                        $results = $query->fetchAll(PDO::FETCH_OBJ);
                                        
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
                                    <label>Quantidade Total<span style="color:red;">*</span></label>
                                    <input class="form-control" type="number" name="quantitytotal" 
                                           min="0" max="9999" required autocomplete="off" />
                                </div>

                                <div class="form-group">
                                    <label>Número ISBN<span style="color:red;">*</span></label>
                                    <input class="form-control" type="text" name="isbn" 
                                           maxlength="50" required autocomplete="off" />
                                    <p class="help-block">ISBN é um Número Padrão Internacional de Livro. O ISBN deve ser único</p>
                                </div>

                                <div class="form-group">
                                    <label>Preço<span style="color:red;">*</span></label>
                                    <input class="form-control" type="number" name="price" 
                                           step="0.01" min="0" max="99999.99" required autocomplete="off" />
                                </div>

                                <button type="submit" name="add" class="btn btn-info">Adicionar</button>

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