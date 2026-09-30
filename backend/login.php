<?php

require_once "conecta.php";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    login($conect);
}

?>

<!doctype html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <title>Entrar</title>

    <link rel="stylesheet" href="/styles/login-register.css" />
    <link rel="shortcut icon" href="/img/Logo.png" type="image/x-icon" />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect"
        href="https://fonts.gstatic.com"
        crossorigin />

    <link
        href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap"
        rel="stylesheet" />

    <link
        rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" />
</head>

<body>

    <div class="bg-books" id="bgBooks" aria-hidden="true"></div>

    <header>

        <div>
            <img
                src="/img/Logo.png"
                alt="Logo"
                height="30px" />

            <a href="index.html">REPRE</a>
        </div>

        <a href="index.html" class="btn back">
            <i class="fa-solid fa-right-from-bracket"></i>
            Voltar
        </a>

    </header>


    <main>

        <div class="card">

            <h2>
                Faça login para acessar sua conta e turma.
            </h2>

            <form
                action="login.php"
                method="post"
                class="principal-form"
                name="formLogin">

                <input
                    class="form-input"
                    type="email"
                    name="email"
                    placeholder="Email"
                    required />

                <input
                    class="form-input"
                    type="password"
                    name="senha"
                    placeholder="Senha"
                    required />

                <button
                    type="submit"
                    class="btn-submit form-input"
                    name="entrar">
                    Entrar
                </button>

            </form>

            <a href="#" class="forgot-password">
                Esqueci minha senha
            </a>

            <div class="register-link">

                <span>
                    Não tem uma conta?
                </span>

                <a href="cadastro.html">
                    Cadastre-se
                </a>

            </div>

        </div>

    </main>


    <footer>
        © 2026 Repre · Estude com organização
    </footer>

    <script src="funcaolivros.js"></script>

</body>

</html>