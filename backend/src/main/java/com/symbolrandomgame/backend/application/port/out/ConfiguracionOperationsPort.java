package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.application.model.ConfiguracionCommand;
import com.symbolrandomgame.backend.application.model.ConfiguracionData;
import com.symbolrandomgame.backend.application.model.PaletaData;

public interface ConfiguracionOperationsPort {
    boolean usuarioExiste(int idUsuario);
    ConfiguracionData obtener(int idUsuario);
    java.util.List<PaletaData> paletas();
    Integer avatarActual(int idUsuario);
    Integer avatarPredeterminado();
    void guardar(int idUsuario, ConfiguracionCommand request, int idPaleta, int idAvatar);
}
