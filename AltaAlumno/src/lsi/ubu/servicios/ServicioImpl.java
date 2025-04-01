package lsi.ubu.servicios;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import lsi.ubu.excepciones.AltaAlumnoException;
import lsi.ubu.util.PoolDeConexiones;
import lsi.ubu.util.exceptions.SGBDError;
import lsi.ubu.util.exceptions.oracle.OracleSGBDErrorUtil;

public class ServicioImpl implements Servicio {
	int idMatricula = 1;
	public void matricular(String alumno, String asig, int grupo) throws SQLException {
		// A completar por el alumno
		 Connection conn = null;
		 PreparedStatement inMat = null;
		 PreparedStatement upPlazas = null;
		 
		 try {
			 PoolDeConexiones pool = PoolDeConexiones.getInstance();
			 conn = pool.getConnection();
			 
			 inMat = conn.prepareStatement("INSERT INTO matriculas (idMatricula, alumno, asig, grupo) VALUES (seq_matricula.nextval, ?, ?, ?)");
			 inMat.setString(1, alumno);
			 inMat.setString(2, asig);
			 inMat.setInt(3, grupo);
			 int nFilas = inMat.executeUpdate();
			 if (nFilas == 0) throw new AltaAlumnoException(1);
			 
			 upPlazas = conn.prepareStatement( "UPDATE grupos SET plazasLibres = (plazasLibres - 1) WHERE idGrupo = ? AND asignatura = ? AND plazasLibres > 0");
			 upPlazas.setInt(1, grupo);
			 upPlazas.setString(2, asig);
			 nFilas = upPlazas.executeUpdate();
			 if (nFilas == 0) throw new AltaAlumnoException(2);
			 conn.commit();
		 }
		 catch(SQLException e) {
			 if (conn!=null) conn.rollback();
			 if (e instanceof AltaAlumnoException) throw (AltaAlumnoException) e;
			 if(new OracleSGBDErrorUtil().checkExceptionToCode(e, SGBDError.FK_VIOLATED))
			 throw e;
		 }
		 finally {
			 if(inMat != null) inMat.close();
			 if(upPlazas != null) upPlazas.close();
			 if(conn != null) conn.close();
		 }
		
	}
}
