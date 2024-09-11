CREATE TABLE Generos (
    id_genero INT PRIMARY KEY IDENTITY,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE Directores (
    id_director INT PRIMARY KEY IDENTITY,
    nombre VARCHAR(100) NOT NULL,
    pais_origen VARCHAR(50)
);

CREATE TABLE Actores (
    id_actor INT PRIMARY KEY IDENTITY,
    nombre VARCHAR(100) NOT NULL,
    pais_origen VARCHAR(50)
);

CREATE TABLE Peliculas (
    id_pelicula INT PRIMARY KEY IDENTITY,
    titulo VARCHAR(100) NOT NULL,
    anio_estreno INT,
    duracion INT,
    id_genero INT,
    id_director INT,
    cantidad_disponible INT,
    FOREIGN KEY (id_genero) REFERENCES Generos(id_genero),
    FOREIGN KEY (id_director) REFERENCES Directores(id_director)
);

CREATE TABLE Clientes (
    id_cliente INT PRIMARY KEY IDENTITY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(100),
    telefono VARCHAR(20)
);

CREATE TABLE Alquileres (
    id_alquiler INT PRIMARY KEY IDENTITY,
    id_pelicula INT,
    id_cliente INT,
    fecha_alquiler DATE,
    fecha_devolucion DATE,
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas(id_pelicula),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

INSERT INTO Generos (nombre) VALUES 
('Acción'), 
('Comedia'), 
('Drama'), 
('Ciencia Ficción');

INSERT INTO Directores (nombre, pais_origen) VALUES 
('Steven Spielberg', 'Estados Unidos'), 
('Christopher Nolan', 'Reino Unido'), 
('Quentin Tarantino', 'Estados Unidos');

INSERT INTO Actores (nombre, pais_origen) VALUES 
('Leonardo DiCaprio', 'Estados Unidos'), 
('Tom Hanks', 'Estados Unidos'), 
('Scarlett Johansson', 'Estados Unidos');

INSERT INTO Peliculas (titulo, anio_estreno, duracion, id_genero, id_director, cantidad_disponible) VALUES 
('Inception', 2010, 148, 4, 2, 5),
('Pulp Fiction', 1994, 154, 3, 3, 3),
('Jurassic Park', 1993, 127, 1, 1, 2);

INSERT INTO Clientes (nombre, direccion, telefono) VALUES 
('John Doe', '123 Elm St', '555-1234'), 
('Jane Smith', '456 Oak St', '555-5678'), 
('Alice Johnson', '789 Pine St', '555-9012');

INSERT INTO Alquileres (id_pelicula, id_cliente, fecha_alquiler, fecha_devolucion) VALUES 
(1, 1, '2024-09-01', NULL),
(2, 2, '2024-09-02', '2024-09-09'),
(3, 3, '2024-09-03', NULL);

CREATE VIEW vista_peliculas_disponibles AS
SELECT 
    p.titulo AS Título, 
    p.anio_estreno AS Año, 
    g.nombre AS Género, 
    d.nombre AS Director, 
    p.cantidad_disponible AS Disponibles
FROM 
    Peliculas p
INNER JOIN 
    Generos g ON p.id_genero = g.id_genero
INNER JOIN 
    Directores d ON p.id_director = d.id_director
WHERE 
    p.cantidad_disponible > 0;

CREATE VIEW vista_top_peliculas AS
SELECT 
    p.titulo AS Título, 
    COUNT(a.id_pelicula) AS Veces_Alquilada
FROM 
    Peliculas p
INNER JOIN 
    Alquileres a ON p.id_pelicula = a.id_pelicula
GROUP BY 
    p.titulo
ORDER BY 
    Veces_Alquilada DESC;


CREATE FUNCTION fn_total_alquileres_cliente (@id_cliente INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_alquileres INT;
    SELECT @total_alquileres = COUNT(*)
    FROM Alquileres
    WHERE id_cliente = @id_cliente;
    RETURN @total_alquileres;
END;

CREATE FUNCTION fn_disponibilidad_pelicula (@id_pelicula INT)
RETURNS BIT
AS
BEGIN
    DECLARE @disponible BIT;
    SELECT @disponible = CASE WHEN cantidad_disponible > 0 THEN 1 ELSE 0 END
    FROM Peliculas
    WHERE id_pelicula = @id_pelicula;
    RETURN @disponible;
END;

CREATE PROCEDURE sp_realizar_alquiler 
    @id_cliente INT, 
    @id_pelicula INT, 
    @fecha_alquiler DATE
AS
BEGIN

    IF (SELECT dbo.fn_disponibilidad_pelicula(@id_pelicula)) = 1
    BEGIN

        INSERT INTO Alquileres (id_cliente, id_pelicula, fecha_alquiler)
        VALUES (@id_cliente, @id_pelicula, @fecha_alquiler);

        UPDATE Peliculas
        SET cantidad_disponible = cantidad_disponible - 1
        WHERE id_pelicula = @id_pelicula;
    END
    ELSE
    BEGIN
        PRINT 'La película no está disponible para alquiler.';
    END
END;

CREATE PROCEDURE sp_registrar_devolucion 
    @id_alquiler INT, 
    @fecha_devolucion DATE
AS
BEGIN

    UPDATE Alquileres
    SET fecha_devolucion = @fecha_devolucion
    WHERE id_alquiler = @id_alquiler;
    
    DECLARE @id_pelicula INT;
    SELECT @id_pelicula = id_pelicula FROM Alquileres WHERE id_alquiler = @id_alquiler;
    
    UPDATE Peliculas
    SET cantidad_disponible = cantidad_disponible + 1
    WHERE id_pelicula = @id_pelicula;
END;



CREATE TRIGGER trg_actualizar_disponibilidad_alquiler
ON Alquileres
AFTER INSERT
AS
BEGIN
    DECLARE @id_pelicula INT;
    SELECT @id_pelicula = i.id_pelicula FROM inserted i;
    
    UPDATE Peliculas
    SET cantidad_disponible = cantidad_disponible - 1
    WHERE id_pelicula = @id_pelicula;
END;
