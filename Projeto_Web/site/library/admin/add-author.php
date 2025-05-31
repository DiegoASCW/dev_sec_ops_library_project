<?php
session_start();
error_reporting(0);

include('../includes/config.php');

// Verificar autenticação
if (strlen($_SESSION['alogin']) == 0) {
    header('location:index.php');
    exit();
}

// Gerar token CSRF se não existir
if (!isset($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

if (isset($_POST['create'])) {
    // Verificar token CSRF
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $_SESSION['error'] = "Token de segurança inválido";
        header('location:manage-authors.php');
        exit();
    }
    
    // Validar e sanitizar dados
    $author = trim($_POST['author']);
    
    // Validações
    if (empty($author)) {
        $_SESSION['error'] = "Nome do autor é obrigatório";
        header('location:manage-authors.php');
        exit();
    }
    
    if (strlen($author) > 255) {
        $_SESSION['error'] = "Nome do autor muito longo (máximo 255 caracteres)";
        header('location:manage-authors.php');
        exit();
    }
    
    try {
        // Verificar se autor já existe
        $checkSql = "SELECT AuthorName FROM tblauthors WHERE AuthorName = :author";
        $checkQuery = $dbh->prepare($checkSql);
        $checkQuery->bindParam(':author', $author, PDO::PARAM_STR);
        $checkQuery->execute();
        
        if ($checkQuery->rowCount() > 0) {
            $_SESSION['error'] = "Este autor já existe";
            header('location:manage-authors.php');
            exit();
        }
        
        // Inserir autor
        $sql = "INSERT INTO tblauthors(AuthorName) VALUES(:author)";
        $query = $dbh->prepare($sql);
        $query->bindParam(':author', $author, PDO::PARAM_STR);
        $query->execute();
        
        $lastInsertId = $dbh->lastInsertId();
        if ($lastInsertId) {
            $_SESSION['msg'] = "Autor adicionado com sucesso";
            header('location:manage-authors.php');
            exit();
        } else {
            $_SESSION['error'] = "Erro ao adicionar autor";
            header('location:manage-authors.php');
            exit();
        }
        
    } catch (PDOException $e) {
        $_SESSION['error'] = "Erro no banco de dados: " . $e->getMessage();
        header('location:manage-authors.php');
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
    <title>Openshelf | Adicionar Autor</title>
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
    <!------MENU SECTION START-->
    <?php include('includes/header.php'); ?>
    <!-- MENU SECTION END-->
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">Adicionar Autor</h4>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                    <div class="panel panel-info">
                        <div class="panel-heading">
                            Informações do Autor
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>" />
                                
                                <div class="form-group">
                                    <label>Nome do Autor</label>
                                    <input class="form-control" type="text" name="author" 
                                           maxlength="255" autocomplete="off" required />
                                </div>
                                
                                <button type="submit" name="create" class="btn btn-info">Adicionar</button>
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