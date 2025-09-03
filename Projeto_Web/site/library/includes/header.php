<?php
// Start the session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
?>
<div class="navbar navbar-inverse set-radius-zero">
    <div class="container">
        <div class="navbar-header">
            <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>
            <a class="navbar-brand">
                <img src="assets/img/logo.png" alt="Library Logo" />
            </a>
        </div>

        <?php if (!empty($_SESSION['login'])): ?>
            <div class="right-div">
                <a href="logout.php" class="btn btn-danger pull-right">LOG ME OUT</a>
            </div>
        <?php endif; ?>
    </div>
</div>

<section class="menu-section">
    <div class="container">
        <div class="row">
            <div class="col-md-12">
                <div class="navbar-collapse collapse">
                    <ul id="menu-top" class="nav navbar-nav navbar-right">
                        <?php if (!empty($_SESSION['login'])): ?>
                            <li><a href="dashboard.php" class="menu-top-active">DASHBOARD</a></li>
                            <li>
                                <a href="#" class="dropdown-toggle" id="ddlmenuItem" data-toggle="dropdown">Account <i class="fa fa-angle-down"></i></a>
                                <ul class="dropdown-menu" role="menu" aria-labelledby="ddlmenuItem">
                                    <li><a href="my-profile.php">My Profile</a></li>
                                    <li><a href="change-password.php">Change Password</a></li>
                                </ul>
                            </li>
                            <li>
                                <a href="#" class="dropdown-toggle" id="ddlmenuItem" data-toggle="dropdown">Books <i class="fa fa-angle-down"></i></a>
                                <ul class="dropdown-menu" role="menu" aria-labelledby="ddlmenuItem">
                                    <li><a href="list-all-books.php">List Books</a></li>
                                    <li><a href="list-favorite-books.php">Favorite Books</a></li>
                                </ul>
                            </li>
                            <li><a href="issued-books.php">Issued Books</a></li>
                        <?php else: ?>
                            <li><a href="adminlogin.php">Admin Login</a></li>
                            <li><a href="signup.php">User Signup</a></li>
                            <li><a href="index.php">User Login</a></li>
                        <?php endif; ?>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</section>
