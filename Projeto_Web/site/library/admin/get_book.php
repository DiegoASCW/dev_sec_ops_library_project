<?php
require_once "../includes/config.php";

if (!empty($_POST["bookid"])) {
    $bookid = $_POST["bookid"];
    $sql = "SELECT BookName,id FROM tblbooks WHERE (ISBNNumber=:bookid OR BookName LIKE :bookname)";
    $query = $dbh->prepare($sql);
    $query->bindParam(':bookid', $bookid, PDO::PARAM_STR);
    $bookname = "%" . $bookid . "%";
    $query->bindParam(':bookname', $bookname, PDO::PARAM_STR);
    $query->execute();
    $results = $query->fetchAll(PDO::FETCH_OBJ);
    
    if ($query->rowCount() > 0) {
        foreach ($results as $result) { ?>
            <option value="<?php echo htmlentities($result->id); ?>"><?php echo htmlentities($result->BookName); ?></option>
        <?php
        }
        echo "<script>$('#submit').prop('disabled',false);</script>";
    } else { ?>
        <option class="others">Invalid ISBN Number or Book Title</option>
        <?php
        echo "<script>$('#submit').prop('disabled',true);</script>";
    }
}
?>