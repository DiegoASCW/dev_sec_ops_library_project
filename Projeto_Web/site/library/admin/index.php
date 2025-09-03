<?php
// Inicia a sessão
session_start();

// Inclui as configurações necessárias
include('../includes/config.php');
include('../includes/cognito-config.php'); // <-- Adicionado para o Cognito

// Se o admin já estiver logado, redireciona para o dashboard
if (isset($_SESSION['alogin']) && !empty($_SESSION['alogin'])) {
    header("Location: dashboard.php");
    exit();
}

// --- LÓGICA DE LOGIN ATUALIZADA COM COGNITO ---
if (isset($_POST['login'])) {
    $email = $_POST['emailid']; // <-- Alterado de 'username' para 'emailid'
    $password = $_POST['password'];

    try {
        // Tenta autenticar no Cognito
        $result = $cognitoClient->initiateAuth([
            'AuthFlow'       => 'USER_PASSWORD_AUTH',
            'ClientId'       => AWS_COGNITO_CLIENT_ID,
            'AuthParameters' => [
                'USERNAME'   => $email,
                'PASSWORD'   => $password,
            ],
        ]);

        // Se o login for bem-sucedido, define a sessão do admin
        $_SESSION['alogin'] = $email;
        
        // Redireciona para o dashboard
        echo "<script type='text/javascript'> document.location ='dashboard.php'; </script>";
        exit();

    } catch (Exception $e) {
        // Se der erro, mostra um alerta com a mensagem específica
        echo "<script>alert('Detalhes inválidos: " . addslashes($e->getMessage()) . "');</script>";
    }
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w.g.org/1999/xhtml">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf - Admin Login</title> <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <link href="assets/css/style.css" rel="stylesheet" />
    <link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />

</head>

<body>
    <?php include('includes/header.php'); ?>
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">ADMIN LOGIN FORM</h4>
                </div>
            </div>

            <div class="row">
                <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                    <div class="panel panel-info">
                        <div class="panel-heading">
                            LOGIN FORM
                        </div>
                        <div class="panel-body">
                            <form role="form" method="post">

                                <div class="form-group">
                                    <label>Enter Email</label>
                                    <input class="form-control" type="email" name="emailid" required />
                                </div>
                                <div class="form-group">
                                    <label>Password</label>
                                    <input class="form-control" type="password" name="password" required />
                                </div>
                                <button type="submit" name="login" class="btn btn-info">LOGIN </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            </div>
    </div>
    <?php include('includes/footer.php'); ?>
    <script src="assets/js/jquery-1.10.2.js"></script>
    <script src="assets/js/bootstrap.js"></script>
    <script src="assets/js/jquery.dataTables.js"></script>
    <script src="assets/js/custom.js"></script>
</body>

</html>