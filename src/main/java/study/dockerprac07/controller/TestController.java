package study.dockerprac07.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @GetMapping
    public String test() {
//        return "시ㅏ바꺼";
        return "현대에는 AI한테 질문하고 멍때리는 사람을 개발자라고 한다.";
    }
}
