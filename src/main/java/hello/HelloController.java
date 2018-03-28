package hello;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import java.util.Date;

@RestController
public class HelloController {

    @RequestMapping("/")
    public String index() {
        return "<p> Greetings from ..... </p>"
        + "<p> now is: " + new Date() + "</p>" 
        + "\n <p> ----- this instance is in stage: "+ System.getenv("stage")+ "</p>"  
        + "\n <p> ----- I'm running on: " + System.getProperty("os.name");
    }

}