<?php
// Inicia a sessão antes de destruí-la
session_start();

// Limpa todas as variáveis de sessão
$_SESSION = array();

// Remove o cookie de sessão se existir
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 3600,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

// Destrói a sessão
session_destroy();

// Redireciona para a página de login
header("Location: ../adminlogin.php");
exit(); // Importante: sempre use exit após header redirect
?>