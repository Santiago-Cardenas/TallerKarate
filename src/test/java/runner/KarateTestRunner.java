package runner;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class KarateTestRunner {

    @Test
    void testParallel() {
        // -Dkarate.options="--tags @Issue-3" sobrescribe los tags definidos aquí
        Results results = Runner.path("classpath:features")
                .tags("~@ignore")
                .reportDir("target/karate-reports")
                .outputCucumberJson(true)   // JSON compatible con Cucumber: lo usa el pipeline para actualizar los Issues
                .parallel(1);               // un hilo: las máquinas de estado del servidor son compartidas

        // Hace fallar el build de Gradle si algún escenario falla
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
