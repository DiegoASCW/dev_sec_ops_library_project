<?php
session_start();
error_reporting(0);
include('../includes/config.php');

if(strlen($_SESSION['alogin'])==0) {   
    header('location:index.php');
    exit();
}

if(isset($_GET['del'])) {
    $id = $_GET['del'];
    $sql = "delete from tblauthors WHERE id=:id";
    $query = $dbh->prepare($sql);
    $query->bindParam(':id', $id, PDO::PARAM_STR);
    $query->execute();
    $_SESSION['delmsg'] = "Author deleted";
    header('location:manage-authors.php');
    exit();
}
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />
    <meta name="author" content="" />
    <title>Openshelf | Manage Authors</title>
    <!-- BOOTSTRAP CORE STYLE  -->
    <link href="assets/css/bootstrap.css" rel="stylesheet" />
    <!-- FONT AWESOME STYLE  -->
    <link href="assets/css/font-awesome.css" rel="stylesheet" />
    <!-- DATATABLE STYLE  -->
    <link href="assets/js/dataTables/dataTables.bootstrap.css" rel="stylesheet" />
    <!-- CUSTOM STYLE  -->
    <link href="assets/css/style.css" rel="stylesheet" />
    <!-- GOOGLE FONT -->
    <link href='http://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css' />
</head>
<body>
    <!------MENU SECTION START-->
    <?php include('includes/header.php');?>
    <!-- MENU SECTION END-->
    <div class="content-wrapper">
        <div class="container">
            <div class="row pad-botm">
                <div class="col-md-12">
                    <h4 class="header-line">Manage Authors</h4>
                </div>
            </div>
            
            <!-- Mensagens de feedback -->
            <div class="row">
                <?php if(isset($_SESSION['error']) && $_SESSION['error'] != "") { ?>
                <div class="col-md-6">
                    <div class="alert alert-danger">
                        <strong>Error:</strong> 
                        <?php echo htmlentities($_SESSION['error']); ?>
                        <?php $_SESSION['error'] = ""; ?>
                    </div>
                </div>
                <?php } ?>
                
                <?php if(isset($_SESSION['msg']) && $_SESSION['msg'] != "") { ?>
                <div class="col-md-6">
                    <div class="alert alert-success">
                        <strong>Success:</strong> 
                        <?php echo htmlentities($_SESSION['msg']); ?>
                        <?php $_SESSION['msg'] = ""; ?>
                    </div>
                </div>
                <?php } ?>
                
                <?php if(isset($_SESSION['updatemsg']) && $_SESSION['updatemsg'] != "") { ?>
                <div class="col-md-6">
                    <div class="alert alert-success">
                        <strong>Success:</strong> 
                        <?php echo htmlentities($_SESSION['updatemsg']); ?>
                        <?php $_SESSION['updatemsg'] = ""; ?>
                    </div>
                </div>
                <?php } ?>
                
                <?php if(isset($_SESSION['delmsg']) && $_SESSION['delmsg'] != "") { ?>
                <div class="col-md-6">
                    <div class="alert alert-success">
                        <strong>Success:</strong> 
                        <?php echo htmlentities($_SESSION['delmsg']); ?>
                        <?php $_SESSION['delmsg'] = ""; ?>
                    </div>
                </div>
                <?php } ?>
            </div>

            <div class="row">
                <div class="col-md-12">
                    <!-- Advanced Tables -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Authors Listing
                        </div>
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered table-hover" id="dataTables-example">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Author</th>
                                            <th>Creation Date</th>
                                            <th>Updation Date</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php 
                                        $url = 'http://api-gateway-service:5000/author/list';
                                        
                                        $data = ["stdId" => $_SESSION['alogin']];
                                        $options = [
                                            'http' => [
                                                'header' => "Content-Type: application/json\r\n",
                                                'method' => 'GET',
                                                'content' => json_encode($data)
                                            ],
                                        ];
                                        
                                        $context = stream_context_create($options);
                                        $result = @file_get_contents($url, false, $context);
                                        
                                        $cnt = 1;
                                        
                                        if ($result === false) {
                                            echo "<tr><td colspan='5'>Erro ao consultar autores.</td></tr>";
                                        } else {
                                            $responseData = json_decode($result, true);
                                            
                                            // Verifica se houve erro no JSON
                                            if (json_last_error() !== JSON_ERROR_NONE) {
                                                echo "<tr><td colspan='5'>Erro ao processar resposta da API.</td></tr>";
                                            } else if (isset($responseData['error'])) {
                                                echo "<tr><td colspan='5'>Erro: " . htmlentities($responseData['error']) . "</td></tr>";
                                            } else if (!empty($responseData) && is_array($responseData)) {
                                                foreach ($responseData as $author) {
                                                    $id = isset($author['id']) ? $author['id'] : '';
                                                    $AuthorName = isset($author['AuthorName']) ? $author['AuthorName'] : '';
                                                    $creationDate = isset($author['creationDate']) ? $author['creationDate'] : '';
                                                    $UpdationDate = isset($author['UpdationDate']) ? $author['UpdationDate'] : '';
                                                    ?>
                                                    <tr class='odd gradeX'>
                                                        <td class='center'><?php echo htmlentities($cnt); ?></td>
                                                        <td class='center'><?php echo htmlentities($AuthorName); ?></td>
                                                        <td class='center'><?php echo htmlentities($creationDate); ?></td>
                                                        <td class='center'><?php echo htmlentities($UpdationDate); ?></td>
                                                        <td class='center'>
                                                            <a href='edit-author.php?athrid=<?php echo htmlentities($id); ?>'>
                                                                <button class='btn btn-primary'>
                                                                    <i class='fa fa-edit'></i> Edit
                                                                </button>
                                                            </a>
                                                            <a href='manage-authors.php?del=<?php echo htmlentities($id); ?>' 
                                                               onclick='return confirm("Are you sure you want to delete?");'>
                                                                <button class='btn btn-danger'>
                                                                    <i class='fa fa-trash'></i> Delete
                                                                </button>
                                                            </a>
                                                        </td>
                                                    </tr>
                                                    <?php 
                                                    $cnt++;
                                                }
                                            } else {
                                                echo "<tr><td colspan='5'>Nenhum autor encontrado.</td></tr>";
                                            }
                                        }
                                        ?>                                      
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                    <!--End Advanced Tables -->
                </div>
            </div>
        </div>
    </div>

    <!-- CONTENT-WRAPPER SECTION END-->
    <?php include('includes/footer.php');?>
    <!-- FOOTER SECTION END-->
    
    <!-- JAVASCRIPT FILES PLACED AT THE BOTTOM TO REDUCE THE LOADING TIME  -->
    <!-- CORE JQUERY  -->
    <script src="assets/js/jquery-1.10.2.js"></script>
    <!-- BOOTSTRAP SCRIPTS  -->
    <script src="assets/js/bootstrap.js"></script>
    <!-- DATATABLE SCRIPTS  -->
    <script src="assets/js/dataTables/jquery.dataTables.js"></script>
    <script src="assets/js/dataTables/dataTables.bootstrap.js"></script>
    <!-- CUSTOM SCRIPTS  -->
    <script src="assets/js/custom.js"></script>
</body>
</html>