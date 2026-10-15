package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.application.model.GuardarPuntuacionCommand;
import com.symbolrandomgame.backend.application.model.ModoData;
import com.symbolrandomgame.backend.application.model.NivelData;
import com.symbolrandomgame.backend.application.model.PuntuacionData;

public interface PuntuacionOperationsPort {
    java.util.List<PuntuacionData> obtenerTodas();
    boolean usuarioExiste(int idUsuario);
    boolean puntuacionExiste(int idPuntuacion);
    int eliminarPartidaPropia(int idPuntuacion, int idUsuario);
    java.util.List<ModoData> modos();
    Integer crearModo(String nombre);
    NivelData guardarNivel(
            int modoId, String nombre, int digitos, int tiempo, int vidas
    );
    int crearPartida(int usuarioId, int modoId, int nivelId, java.time.LocalDateTime inicio,
                     java.time.LocalDateTime fin, int resultado);
    void guardarPuntuacion(NivelData nivel, GuardarPuntuacionCommand request, int partidaId);
}
