package lsi.ubu.tests;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import lsi.ubu.excepciones.AltaAlumnoException;
import lsi.ubu.servicios.Servicio;
import lsi.ubu.servicios.ServicioImpl;
import lsi.ubu.util.PoolDeConexiones;

public class Tests {

	/** Logger. */
	private static final Logger LOGGER = LoggerFactory.getLogger(Tests.class);

	public void ejecutarTests() throws SQLException {

		Servicio servicio = new ServicioImpl();

		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {
			PoolDeConexiones p = PoolDeConexiones.getInstance();

			// Matriculamos en el grupo lleno
			try {
				servicio.matricular("Julian", "OFIM", 1); // sale mal porque el grupo esta lleno
				LOGGER.info("NO se da cuenta de que el grupo esta lleno MAL");
			} catch (AltaAlumnoException e) {
				if (e.getErrorCode() == AltaAlumnoException.SIN_PLAZAS) {
					LOGGER.info("Se da cuenta de que el grupo esta lleno OK");
				}
			}

			try {
				servicio.matricular("Pedro", "OFIM", 3); // sale mal porque no existe el grupo
				LOGGER.info("NO se da cuenta de que el grupo no existe MAL");
			} catch (AltaAlumnoException e) {
				if (e.getErrorCode() == AltaAlumnoException.NO_EXISTE_ASIG_O_GRUPO) {
					LOGGER.info("Se da cuenta de que el grupo no existe OK");
				}
			}

			try {
				servicio.matricular("Pedro", "ALGEBRA", 1); // sale mal porque no existe la asignatura
				LOGGER.info("NO se da cuenta de que la asignatura no existe MAL");
			} catch (AltaAlumnoException e) {
				if (e.getErrorCode() == AltaAlumnoException.NO_EXISTE_ASIG_O_GRUPO) {
					LOGGER.info("Se da cuenta de que la asignatura no existe OK");
				}
			}

			servicio.matricular("Pedro", "FPROG", 1); // matricula satisfactoria

			/*
			 * Seleccionar datos de la base de datos para verificar la matriculacion previa
			 * fue correcta.
			 */
			con = p.getConnection();

			String query = "";
			query += " SELECT grupos.idgrupo || grupos.asignatura || plazaslibres || idmatricula || alumno ";
			query += " FROM grupos ";
			query += " LEFT JOIN matriculas ON matriculas.grupo = grupos.idGrupo ";
			query += " ORDER BY grupos.idgrupo, grupos.asignatura, plazaslibres, idmatricula, alumno ";

			st = con.prepareStatement(query);
			rs = st.executeQuery();

			String resultado = "";
			while (rs.next()) {
				resultado += rs.getString(1);
			}

			String teniaQueDar = "1FPROG31PEPE1FPROG32ANA1FPROG33JUAN1FPROG34LUIS1FPROG311Pedro1OFIM01PEPE1OFIM02ANA1OFIM03JUAN1OFIM04LUIS1OFIM011Pedro2FPROG45ANTONIO2FPROG46MERCEDES2FPROG47JESUS2OFIM15ANTONIO2OFIM16MERCEDES2OFIM17JESUS10OFIM4";

			if (resultado.equals(teniaQueDar)) {
				LOGGER.info("Matricula OK");
			} else {
				LOGGER.info("Matricula MAL");
			}

		} catch (SQLException e) {
			LOGGER.error(e.getMessage());
			if (con != null) {
				con.rollback();
			}
		} finally {
			if (rs != null) {
				rs.close();
			}
			if (st != null) {
				st.close();
			}
			if (con != null) {
				con.close();
			}
		}
	}
}
