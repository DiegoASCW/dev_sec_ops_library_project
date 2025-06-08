<?php
session_start();
error_reporting(1);
ini_set('default_charset', 'UTF-8');
mb_internal_encoding('UTF-8');
header('Content-Type: text/html; charset=UTF-8');

include '../includes/config.php';

if (strlen($_SESSION['alogin']) == 0) {
  header('location:index.php');
    exit;
}

if (!isset($_GET['isbn']) || !is_numeric($_GET['isbn'])) {
    die('ISBN inválido.');
}

$isbn = intval($_GET['isbn']);
$admin_name = $_SESSION['alogin'];

// POST de novo comentário
if (isset($_POST['submitComment'])) {
    $texto = trim($_POST['comment']);
    if ($texto === '') {
        $error = "Comentário não pode ficar vazio.";
    } else {
        $sql = "INSERT INTO tblcomment (Userid, ISBNNumber, Comment) 
                VALUES (:uid, :isbn, :comment)";
        $q = $dbh->prepare($sql);
        $q->bindParam(':uid', $admin_name,   PDO::PARAM_STR);
        $q->bindParam(':isbn', $isbn,        PDO::PARAM_INT);
        $q->bindParam(':comment', $texto,    PDO::PARAM_STR);
        $q->execute();
        $_SESSION['msg'] = "Comentário enviado com sucesso!";
        header("Location: book-comments.php?isbn={$isbn}");
        exit;
    }
}

// Busca dados do livro por ISBN
$sql = "SELECT b.BookName, a.AuthorName 
        FROM tblbooks b
        JOIN tblauthors a ON a.id = b.AuthorId
        WHERE b.ISBNNumber = :isbn";
$q = $dbh->prepare($sql);
$q->bindParam(':isbn', $isbn, PDO::PARAM_INT);
$q->execute();
$book = $q->fetch(PDO::FETCH_OBJ);
if (!$book) {
    die('Livro não encontrado.');
}

// Busca comentários do livro por ISBN
$sql = "SELECT c.Comment, c.CreationDate, COALESCE(s.FullName, a.UserName) AS AuthorName
        FROM tblcomment c
        LEFT JOIN tblstudents s ON s.StudentId = c.Userid
        LEFT JOIN admin a ON a.UserName = c.Userid
        WHERE c.ISBNNumber = :isbn
        ORDER BY c.CreationDate DESC";
$q = $dbh->prepare($sql);
$q->bindParam(':isbn', $isbn, PDO::PARAM_INT);
$q->execute();
$comments = $q->fetchAll(PDO::FETCH_OBJ);
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8" />
    <title>Openshelf — Comments</title>
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <link href="assets/css/style.css"   rel="stylesheet" />
</head>
<body>
    <?php include 'includes/header.php'; ?>

    <div class="container content-wrapper">
        <h2>Comentários para: <?php echo htmlentities($book->BookName); ?></h2>
        <p><em>Autor: <?php echo htmlentities($book->AuthorName); ?></em></p>

        <?php if (!empty($error)): ?>
            <div class="alert alert-danger"><?php echo $error; ?></div>
        <?php elseif (!empty($_SESSION['msg'])): ?>
            <div class="alert alert-success">
                <?php echo $_SESSION['msg']; unset($_SESSION['msg']); ?>
            </div>
        <?php endif; ?>

        <div class="panel panel-default">
            <div class="panel-heading">Deixe seu comentário</div>
            <div class="panel-body">
                <form method="post">
                    <div class="form-group">
                        <textarea name="comment" class="form-control" rows="4" required 
                                  placeholder="O que você achou deste livro?"></textarea>
                    </div>
                    <button type="submit" name="submitComment" class="btn btn-primary">
                        Enviar
                    </button>
                </form>
            </div>
        </div>

        <!-- Lista de Comentários -->
        <div class="panel panel-info">
            <div class="panel-heading">
                Comentários (<?php echo count($comments); ?>)
            </div>
            <div class="panel-body">
                <?php if (empty($comments)): ?>
                    <p>Nenhum comentário ainda. Seja o primeiro!</p>
                <?php else: ?>
                    <?php foreach ($comments as $c): ?>
                        <div class="well">
                            <p><?php echo nl2br(htmlentities($c->Comment)); ?></p>
                            <small>
                                Por <strong><?php echo htmlentities($c->AuthorName); ?></strong>
                                em <?php echo date('d/m/Y H:i', 
                                        strtotime($c->CreationDate)); ?>
                            </small>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
        
    </div>

    <?php include 'includes/footer.php'; ?>
    <script src="assets/js/jquery-1.10.2.js"></script>
    <script src="assets/js/bootstrap.js"></script>
</body>
</html>
