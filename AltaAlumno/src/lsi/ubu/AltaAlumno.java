package lsi.ubu;

import java.sql.SQLException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import lsi.ubu.tests.Tests;
import lsi.ubu.util.ExecuteScript;

/**
 * AltaAlumno: Implementa el alta de un alumno en un grupo de una asignatura
 * segun PDF de la carpeta enunciado
 * 
 * @author <a href="mailto:jmaudes@ubu.es">Jesus Maudes</a>
 * @author <a href="mailto:rmartico@ubu.es">Raul Marticorena</a>
 * @version 1.0
 * @since 1.0
 */
public class AltaAlumno {

	private static final Logger LOGGER = LoggerFactory.getLogger(AltaAlumno.class);

	public static void main(String[] args) throws SQLException {

		LOGGER.info("Comienzo de los tests");

		// Crear las tablas y filas en base de datos para la prueba
		ExecuteScript.run("sql/AltaAlumno.sql");

		// Ejecutar los tests
		Tests tests = new Tests();
		tests.ejecutarTests();

		LOGGER.info("Fin de los tests");
	}
}
