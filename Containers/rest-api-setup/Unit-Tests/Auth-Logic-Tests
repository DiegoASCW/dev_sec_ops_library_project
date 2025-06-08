from auth_logic import validate_admin, validate_user

# Simulando um "banco de dados" em memória
fake_users = {
    "admin": {"password": "teste"},
    "maria": {"password": "senha456"}
}

fake_students = {
    "email@teste.com": {
        "password": "senha123",
        "data": ("SID001", "Ativo", "email@teste.com")
    },
    "joao@email.com": {
        "password": "abc123",
        "data": ("SID003", "Inativo", "joao@email.com")
    },
    "lucas.oliveira@gmail.com": {
        "password": "123lucas",
        "data": ("SID002", "Ativo", "lucas.oliveira@gmail.com")
    },
    "beatriz.silva@gmail.com": {
        "password": "senhaBea",
        "data": ("SID005", "Ativo", "beatriz.silva@gmail.com")
    },
    "fernanda.rocha@gmail.com": {
        "password": "fernanda10",
        "data": ("SID010", "Inativo", "fernanda.rocha@gmail.com")
    }
}


# Cursor simulado com lógica
# para retornar dados do "banco de dados" fake
# em vez de uma conexão real com o banco de dados
class FakeCursor:
    def __init__(self):
        self.last_query = ""
        self.last_params = ()
    
    def execute(self, sql, params):
        self.last_query = sql
        self.last_params = params

    def fetchall(self):
        if "FROM admin" in self.last_query:
            username, password = self.last_params
            if username in fake_users and fake_users[username]["password"] == password:
                return [(username,)]
            return []

        if "FROM tblstudents" in self.last_query:
            email, password = self.last_params
            if email in fake_students and fake_students[email]["password"] == password:
                return [fake_students[email]["data"]]
            return []


def test_validate_admin_true():
    cursor = FakeCursor()
    result = validate_admin("admin", "teste", cursor)
    assert result is True, "Usuário admin deveria ser autenticado com sucesso."


def test_validate_admin_false():
    cursor = FakeCursor()
    result = validate_admin("admin", "wrongpass", cursor)
    assert result is False, "Falha: Senha errada deveria impedir o login do admin."


def test_validate_user_success():
    cursor = FakeCursor()
    result = validate_user("email@teste.com", "senha123", cursor)
    expected = ("SID001", "Ativo", "email@teste.com")
    assert result == expected, f"Falha: Esperado {expected}, mas recebeu {result}."


def test_validate_user_fail():
    cursor = FakeCursor()
    result = validate_user("fake@teste.com", "123", cursor)
    assert result is None, "Falha: Email inexistente deveria retornar None."


def test_validate_user_wrong_password():
    cursor = FakeCursor()
    result = validate_user("email@teste.com", "senhaErrada", cursor)
    assert result is None, "Falha: Senha incorreta deveria impedir autenticação do usuário existente."


def test_validate_user_data_fields():
    cursor = FakeCursor()
    result = validate_user("lucas.oliveira@gmail.com", "123lucas", cursor)
    assert isinstance(result, tuple), "Falha: Resultado esperado deveria ser uma tupla."
    assert len(result) == 3, "Falha: Resultado deveria conter 3 campos (StudentId, Status, EmailId)."
    assert result[0].startswith("SID"), f"Falha: StudentId deveria começar com 'SID', recebeu: {result[0]}"
