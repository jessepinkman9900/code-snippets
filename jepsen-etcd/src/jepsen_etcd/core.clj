(ns jepsen-etcd.core
  (:require [jepsen.cli :as cli]
            [jepsen.tests :as tests]))

(defn etcd-test
  "Runs an etcd test"
  [opts]
  (merge tests/noop-test {:pure-generators true} opts))

(defn -main 
  "Handle CLI args"
  [& args]
  (cli/run! (merge (cli/single-test-cmd {:test-fn etcd-test})
                   (cli/serve-cmd))
            args))

