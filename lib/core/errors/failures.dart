abstract class Failure {
  const Failure(this.message);

  final String message;
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}
