#!/bin/bash
set -eo pipefail

run_tg_llama3.1-70b_tests() {
  # Record the start time
  fail=0
  start_time=$(date +%s)

  echo "LOG_METAL: Running run_tg_llama3.1-70b_tests"

  # Llama3.1-70B weights
  llama70b=/mnt/MLPerf/tt_dnn-models/llama/Llama3.1-70B-Instruct/

  LLAMA_DIR=$llama70b FAKE_DEVICE=TG pytest -n auto models/demos/llama3_subdevices/tests/unit_tests ; fail+=$?

  # Record the end time
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "LOG_METAL: run_tg_llama3.1-70b_tests $duration seconds to complete"
  if [[ $fail -ne 0 ]]; then
    exit 1
  fi
}

run_tg_distributed_op_tests() {
  # Record the start time
  fail=0
  start_time=$(date +%s)

  echo "LOG_METAL: Running run_tg_distributed_op_tests"

  pytest tests/ttnn/distributed/test_distributed_layernorm_TG.py ; fail+=$?

  # Record the end time
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "LOG_METAL: run_tg_distributed_op_tests $duration seconds to complete"
  if [[ $fail -ne 0 ]]; then
    exit 1
  fi
}

run_tg_prefetcher_tests() {
  # Record the start time
  fail=0
  start_time=$(date +%s)

  echo "LOG_METAL: Running run_tg_prefetcher_tests"

  pytest tests/ttnn/unit_tests/operations/test_prefetcher_TG.py --timeout 600; fail+=$?

  # Record the end time
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "LOG_METAL: run_tg_prefetcher_tests $duration seconds to complete"
  if [[ $fail -ne 0 ]]; then
    exit 1
  fi
}

run_tg_tests() {
  if [[ "$1" == "unit" ]]; then
    echo "LOG_METAL: running run_tg_unit_tests"
    TT_METAL_ENABLE_REMOTE_CHIP=1 ./build/test/tt_metal/unit_tests_dispatch --gtest_filter="CommandQueueSingleCard*Fixture.*"
    ./build/test/ttnn/galaxy_unit_tests_ttnn
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/unit_tests_device --gtest_filter="GalaxyFixture.*:TGFixture.*"
    ./build/test/tt_metal/unit_tests_device --gtest_filter="GalaxyFixture.*:TGFixture.*"
    TT_METAL_GTEST_NUM_HW_CQS=2 ./build/test/tt_metal/unit_tests_dispatch --gtest_filter="MultiCommandQueueMultiDevice*Fixture.*"

  elif [[ "$1" == "fabric" ]]; then
    echo "LOG_FABRIC: running run_tg_fabric_tests"
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/tt_fabric/fabric_unit_tests --gtest_filter=ControlPlaneFixture.*TG*
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/tt_fabric/fabric_unit_tests --gtest_filter="Fabric2DFixture.*"
    ./build/test/tt_metal/tt_fabric/fabric_unit_tests --gtest_filter="Fabric2DFixture.*"
    # Unicast tests
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 64 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 65 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16 --metal_fabric_init_level 1
    # Unicast tests for push router
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 100 --push_router
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 64 --board_type glx32 --data_kb_per_tx 100 --push_router
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 65 --board_type glx32 --data_kb_per_tx 100 --push_router
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 100 --push_router --metal_fabric_init_level 1
    # Line Mcast tests
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16 --e_depth 7
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16 --w_depth 7
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16 --n_depth 3
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16 --s_depth 3
    TT_METAL_SLOW_DISPATCH_MODE=1 ./build/test/tt_metal/perf_microbenchmark/routing/test_tt_fabric_sanity_wormhole_b0 --fabric_command 1 --board_type glx32 --data_kb_per_tx 10 --num_src_endpoints 20 --num_dest_endpoints 8 --num_links 16 --n_depth 3 --metal_fabric_init_level 1
  elif [[ "$1" == "llama3-70b" ]]; then
    run_tg_llama3.1-70b_tests

  elif [[ "$1" == "prefetcher" ]]; then
    run_tg_prefetcher_tests

  elif [[ "$1" == "distributed-ops" ]]; then
    run_tg_distributed_op_tests

  elif [[ "$1" == "distributed-runtime" ]]; then
    ./build/test/tt_metal/distributed/distributed_unit_tests_wormhole_b0

  else
    echo "LOG_METAL: Unknown model type: $1"
    return 1
  fi
}

main() {
  if [[ -z "$TT_METAL_HOME" ]]; then
    echo "Must provide TT_METAL_HOME in environment" 1>&2
    exit 1
  fi

  if [[ -z "$ARCH_NAME" ]]; then
    echo "Must provide ARCH_NAME in environment" 1>&2
    exit 1
  fi

  # Parse the arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --model)
        model=$2
        shift
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
  done

  # Run all tests
  cd $TT_METAL_HOME
  export PYTHONPATH=$TT_METAL_HOME

  run_tg_tests "$model"
}

main "$@"
