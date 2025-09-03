<?php
// confirm.php
session_start();
include('includes/config.php');
include('includes/cognito-config.php');

if (isset($_POST['confirm'])) {
    $email = $_POST['email'];
    $code = $_POST['code'];

    try {
        $result = $cognitoClient->confirmSignUp([
            'ClientId'         => AWS_COGNITO_CLIENT_ID,
            'SecretHash'       => generateSecretHash($email),
            'Username'         => $email,
            'ConfirmationCode' => $code,
        ]);

        echo '<script>alert("Conta confirmada com sucesso! Você já pode fazer o login."); document.location="index.php";</script>';
        exit();

    } catch (Exception $e) {
        echo "<script>alert('Erro: " . addslashes($e->getMessage()) . "');</script>";
    }
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Openshelf | Confirmar Conta</title>
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
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
                    <h4 class="header-line">CONFIRMAR CONTA</h4>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                    <div class="panel panel-info">
                        <div class="panel-heading">FORMULÁRIO DE CONFIRMAÇÃO</div>
                        <div class="panel-body">
                            <form role="form" method="post">
                                <div class="form-group">
                                    <label>Seu E-mail</label>
                                    <input class="form-control" type="email" name="email" required autocomplete="off" />
                                </div>
                                <div class="form-group">
                                    <label>Código de Confirmação</label>
                                    <input class="form-control" type="text" name="code" required autocomplete="off" />
                                    <p class="help-block">Insira o código que você recebeu no seu e-mail.</p>
                                </div>
                                <button type="submit" name="confirm" class="btn btn-info">CONFIRMAR CONTA</button>
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