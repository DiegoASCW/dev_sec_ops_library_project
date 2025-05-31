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
        header('location:manage-categories.php');
        exit();
    }
    
    // Validar e sanitizar dados
    $category = trim($_POST['category']);
    $status = $_POST['status'];
    
    // Validações
    if (empty($category)) {
        $_SESSION['error'] = "Nome da categoria é obrigatório";
        header('location:manage-categories.php');
        exit();
    }
    
    if (strlen($category) > 255) {
        $_SESSION['error'] = "Nome da categoria muito longo (máximo 255 caracteres)";
        header('location:manage-categories.php');
        exit();
    }
    
    if (!in_array($status, ['0', '1'])) {
        $_SESSION['error'] = "Status inválido";
        header('location:manage-categories.php');
        exit();
    }
    
    try {
        // Verificar se categoria já existe
        $checkSql = "SELECT CategoryName FROM tblcategory WHERE CategoryName = :category";
        $checkQuery = $dbh->prepare($checkSql);
        $checkQuery->bindParam(':category', $category, PDO::PARAM_STR);
        $checkQuery->execute();
        
        if ($checkQuery->rowCount() > 0) {
            $_SESSION['error'] = "Esta categoria já existe";
            header('location:manage-categories.php');
            exit();
        }
        
        // Inserir nova categoria
        $sql = "INSERT INTO tblcategory(CategoryName, Status) VALUES(:category, :status)";
        $query = $dbh->prepare($sql);
        $query->bindParam(':category', $category, PDO::PARAM_STR);
        $query->bindParam(':status', $status, PDO::PARAM_INT);
        $query->execute();
        
        $lastInsertId = $dbh->lastInsertId();
        if ($lastInsertId) {
            $_SESSION['msg'] = "Categoria criada com sucesso";
            header('location:manage-categories.php');
            exit();
        } else {
            $_SESSION['error'] = "Erro ao criar categoria";
            header('location:manage-categories.php');
            exit();
        }
        
    } catch (PDOException $e) {
        $_SESSION['error'] = "Erro no banco de dados: " . $e->getMessage();
        header('location:manage-categories.php');
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
    <title>Openshelf | Adicionar Categorias</title>
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
                    <h4 class="header-line">Adicionar categoria</h4>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                    <div class="panel panel-info">
                        <div class="panel-heading">
                            Informações da Categoria
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>" />
                                
                                <div class="form-group">
                                    <label>Nome da Categoria</label>
                                    <input class="form-control" type="text" name="category" 
                                           maxlength="255" autocomplete="off" required />
                                </div>
                                
                                <div class="form-group">
                                    <label>Status</label>
                                    <div class="radio">
                                        <label>
                                            <input type="radio" name="status" value="1" checked="checked">Ativo
                                        </label>
                                    </div>
                                    <div class="radio">
                                        <label>
                                            <input type="radio" name="status" value="0">Inativo
                                        </label>
                                    </div>
                                </div>
                                
                                <button type="submit" name="create" class="btn btn-info">Criar</button>
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