Create database triggers_ex1
go 
use triggers_ex1
Create table times(
codigo int not null Primary key,
nome varchar(100) not null
)
go
Create table jogos(
codigo int not null Primary Key,
codigo_timeA int not null References times(codigo),
codigo_timeB int not null References times(codigo),
set_timeA int not null,
set_timeB int not null
)

Go 
Create Trigger t_controleJogos on jogos
after insert, update
as
begin
	declare @set_timeA int,
			@set_timeB int
	
	set @set_timeA = (select set_timeA from inserted)
	set @set_timeB = (select set_timeB from inserted)

	if((@set_timeA+@set_timeB)>5) Begin 
		RollBack Transaction 
		RAISERROR('O total de sets não pode ser maior que 5', 16, 1)
	End
	Else Begin
		if(@set_timeB > 3 or @set_timeA > 3) Begin
			RollBack Transaction 
			RAISERROR('Um time não pode fazer mais de 3 sets', 16, 1)
		End
	End
end

Go
INSERT INTO times (codigo, nome) VALUES
(1, 'Time A'),
(2, 'Time B'),
(3, 'Time C'),
(4, 'Time D');
Go


-- Criando função
Create Function fn_geraTabela()
returns @tabela table(
nome_time varchar(100),
total_pontos int,
total_sets_ganhos int,
total_sets_perdidos int,
set_average int
)
Begin
	declare @cod_time int,
			@nome varchar(100),
			@total_pontos int,
			@aux int,
			@set_ganho int,
			@set_perdido int,
			@set_avg int,
			@cont int,
			@max_count int,
			@cod_aux int

	set @cod_time = 1
	set @total_pontos = 0
	set @set_ganho = 0
	set @set_perdido = 0
	set @set_avg =0
	set @cont = 0

	while(@cod_time <=4) begin
	set @nome = (select nome from times where codigo = @cod_time)
	set @aux = (Select COUNT(codigo) from jogos where codigo_timeA = @cod_time and set_timeB = 2)
	if(@aux is not null) Begin
		set @total_pontos = @total_pontos +  (@aux * 2)
	End

	set @aux = (Select COUNT(codigo) from jogos where codigo_timeA = @cod_time and set_timeB != 2 and set_timeA = 3)
	if(@aux is not null) Begin
		set @total_pontos = @total_pontos + (@aux *3)
	End
	

	set @aux = (Select COUNT(codigo) from jogos where codigo_timeA = @cod_time and set_timeA = 2)
	if(@aux is not null) Begin
		set @total_pontos = @total_pontos + (@aux * 1)
	End
	-- Verificando se é time B
	set @aux = (Select COUNT(codigo) from jogos where codigo_timeB = @cod_time and set_timeA = 2)
	if(@aux is not null) Begin
		set @total_pontos = @total_pontos +  (@aux * 2)
	End

	set @aux = (Select COUNT(codigo) from jogos where codigo_timeB = @cod_time and set_timeA != 2 and set_timeB = 3)
	if(@aux is not null) Begin
		set @total_pontos = @total_pontos + (@aux *3)
	End

	set @aux = (Select COUNT(codigo) from jogos where codigo_timeB = @cod_time and set_timeB = 2)
	if(@aux is not null) Begin
		set @total_pontos = @total_pontos + (@aux * 1)
	End
	

	If((Select sum(set_timeA) from jogos where codigo_timeA = @cod_time) is not null) begin
		set @set_ganho = (Select sum(set_timeA) from jogos where codigo_timeA = @cod_time)
	end
	If((Select sum(set_timeB) from jogos where codigo_timeA = @cod_time) is not null) begin
		set @set_perdido = (Select sum(set_timeB) from jogos where codigo_timeA = @cod_time)
	end

	-- Se o time for o B
	if((Select sum(set_timeB) from jogos where codigo_timeB = @cod_time) is not null) begin
		set @set_ganho = @set_ganho + (Select sum(set_timeB) from jogos where codigo_timeB = @cod_time)
	end
	if((Select sum(set_timeA) from jogos where codigo_timeB = @cod_time) is not null) begin
		set @set_perdido = @set_perdido + (Select sum(set_timeA) from jogos where codigo_timeB = @cod_time)
	end
	set @set_avg = @set_ganho - @set_perdido
	

	-- Insert na tabela
	set @set_avg = @set_ganho - @set_perdido

	Insert into @tabela
	Select @nome, @total_pontos, @set_ganho, @set_perdido, @set_avg
	
	set @total_pontos = 0
	set @set_ganho = 0
	set @set_perdido = 0
	set @set_avg = 0
	set @aux = 0
	set @cod_time = @cod_time + 1
end
	Return
End



Go
-- Inserts
INSERT INTO jogos (codigo, codigo_timeA, codigo_timeB, set_timeA, set_timeB)
VALUES
    (1, 1, 2, 3, 2), -- Time 1 vs Time 2 - Time 1 venceu por 3 sets a 2
    (2, 1, 3, 3, 1), -- Time 1 vs Time 3 - Time 1 venceu por 3 sets a 1
    (3, 1, 4, 3, 0), -- Time 1 vs Time 4 - Time 1 venceu por 3 sets a 0
    (4, 2, 3, 2, 3), -- Time 2 vs Time 3 - Time 3 venceu por 3 sets a 2
    (5, 2, 4, 1, 3), -- Time 2 vs Time 4 - Time 4 venceu por 3 sets a 1
    (6, 3, 4, 0, 3); -- Time 3 vs Time 4 - Time 4 venceu por 3 sets a 0


Select * from fn_geraTabela()



