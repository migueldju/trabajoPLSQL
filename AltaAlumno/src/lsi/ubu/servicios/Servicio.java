package lsi.ubu.servicios;

import java.sql.SQLException;

public interface Servicio {

	public void matricular(String alumno, String asig, int grupo) throws SQLException;
}
